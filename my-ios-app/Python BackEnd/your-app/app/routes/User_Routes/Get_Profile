from flask import Blueprint, request, jsonify, session, current_app
from app import db
from app.models.user import User
from app.models.skill import Skill
from app.models.users_skills import UsersSkills
from app.models.users_followers import UsersFollowers
from app.models.users_network import UsersNetwork
from app.utils.user_utils import check_new_email, check_new_username, manage_user_row
import hashlib
import os
import uuid
from werkzeug.utils import secure_filename

user_bp = Blueprint('user', __name__)

def allowed_file(filename):
    allowed_extensions = {'png', 'jpg', 'jpeg', 'gif'}
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in allowed_extensions

def get_user_response(user, session_user_id=None):
    user_row = user.as_dict()
    level = '0' if session_user_id and str(session_user_id) == str(user.id) else '1'
    user_row = manage_user_row(user_row, user.id, level=level)
    # Add skills
    user_skills = Skill.query.join(UsersSkills, Skill.id == UsersSkills.skills_id).filter(UsersSkills.users_id == user.id).all()
    user_row['skills'] = [skill.as_dict() for skill in user_skills]
    # Add relationships if session user
    if session_user_id:
        user_row['relationships'] = {
            "i_follow": UsersFollowers.query.filter_by(users_id1=session_user_id, users_id2=user.id).count() > 0,
            "i_am_followed_by": UsersFollowers.query.filter_by(users_id2=session_user_id, users_id1=user.id).count() > 0,
            "in_my_network": UsersNetwork.query.filter_by(users_id1=session_user_id, users_id2=user.id).count() > 0,
            "i_am_in_their_network": UsersNetwork.query.filter_by(users_id2=session_user_id, users_id1=user.id).count() > 0,
        }
    return user_row

@user_bp.route('/api/user/profile', methods=['GET', 'POST'])
def api_user_profile():
    # GET: fetch profile, POST: edit profile (if session user)
    if request.method == 'GET':
        users_id = request.args.get('users_id', type=int)
        session_user_id = session.get('user_id')

        # Prefer session user if users_id is not provided
        if not users_id and not session_user_id:
            return jsonify({'error': 'login or users_id required!'}), 401
        if not users_id:
            users_id = session_user_id

        user = User.query.filter_by(id=users_id).first()
        if not user:
            return jsonify({'error': "That user doesn't exist!"}), 404

        user_row = get_user_response(user, session_user_id)
        return jsonify({'result': user_row})

    # POST: edit profile (must be session user)
    if request.content_type and request.content_type.startswith('multipart/form-data'):
        data = request.form.to_dict()
        files = request.files
    else:
        data = request.get_json()
        files = {}

    user_id = session.get('user_id')
    if not user_id:
        return jsonify({'error': 'login required!'}), 401

    user = User.query.filter_by(id=user_id).first()
    if not user:
        return jsonify({'error': "The user doesn't exist anymore"}), 404

    # Email update
    if data.get('email') and data['email'] != user.email:
        try:
            check_new_email(data['email'], user.email)
        except Exception as e:
            return jsonify({'error': str(e)}), 400
        user.email = data['email']

    # Username update
    if data.get('username') and data['username'] != user.username:
        try:
            check_new_username(data['username'], user.username)
        except Exception as e:
            return jsonify({'error': str(e)}), 400
        user.username = data['username']

    # Password update
    if data.get('password'):
        user.password = hashlib.md5((os.environ['PASS_SALT'] + data['password']).encode()).hexdigest()

    # Auto-update columns
    auto_update_columns = [
        'fname', 'lname', 'users_types_id', 'cities_id', 'broadcast', 'about',
        'phone', 'device_token', 'lat', 'lng', 'other_skill', 'manual_city'
    ]
    for col in auto_update_columns:
        if col in data and data.get(col) is not None:
            setattr(user, col, data[col])

    # Profile picture update
    if 'profile_picture' in files:
        file = files['profile_picture']
        if file and allowed_file(file.filename):
            filename = secure_filename(f"user_{user.id}_{uuid.uuid4().hex}_{file.filename}")
            upload_folder = current_app.config.get('PROFILE_PIC_UPLOAD_FOLDER', 'uploads/profile_pics')
            os.makedirs(upload_folder, exist_ok=True)
            file_path = os.path.join(upload_folder, filename)
            file.save(file_path)
            profile_pic_url = current_app.config.get('PROFILE_PIC_URL_PREFIX', '/static/profile_pics/')
            user.profile_picture_url = os.path.join(profile_pic_url, filename)

    db.session.commit()

    # Skills update
    if data.get('aSkills') is not None:
        UsersSkills.query.filter_by(users_id=user.id).delete()
        skill_ids = data['aSkills']
        if isinstance(skill_ids, str):
            skill_ids = [int(sid) for sid in skill_ids.split(',') if sid.strip().isdigit()]
        valid_skills = Skill.query.filter(Skill.id.in_(skill_ids)).all()
        for skill in valid_skills:
            db.session.add(UsersSkills(users_id=user.id, skills_id=skill.id))
        db.session.commit()

    # Return updated user profile with skills and relationships
    user_row = get_user_response(user,
                                 