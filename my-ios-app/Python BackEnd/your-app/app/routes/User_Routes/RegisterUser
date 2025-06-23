from flask import Blueprint, request, jsonify, url_for, current_app
from app import db
from app.models.user import User
from app.models.skill import Skill
from app.models.users_skills import UsersSkills
from app.utils.user_utils import check_user_data, check_new_email, manage_user_row
import hashlib
import os
import uuid
import jwt
import datetime
from werkzeug.utils import secure_filename

user_bp = Blueprint('user', __name__)

def allowed_file(filename):
    allowed_extensions = {'png', 'jpg', 'jpeg', 'gif'}
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in allowed_extensions

@user_bp.route('/api/user/register', methods=['POST'])
def api_register_user():
    data = request.form.to_dict()
    files = request.files
    try:
        check_user_data(data)
    except Exception as e:
        return jsonify({'error': str(e)}), 400

    try:
        check_new_email(data['email'])
        # Always set username to email for simplicity
        data['username'] = data['email']
        # No need to check_new_username since email is unique
    except Exception as e:
        return jsonify({'error': str(e)}), 400

    # Hash password (MD5 for now, but recommend werkzeug.security.generate_password_hash for production)
    password_hash = hashlib.md5((os.environ['PASS_SALT'] + data['password']).encode()).hexdigest()

    user = User(
        email=data['email'],
        about=data.get('about', ''),
        broadcast=data.get('broadcast', ''),
        phone=data.get('phone', ''),
        cities_id=data.get('cities_id'),
        users_types_id=data.get('users_types_id'),
        password=password_hash,
        fname=data.get('fname', ''),
        lname=data.get('lname', ''),
        username=data['email'],  # Username is always email
        confirmed=True,  # Allow immediate login
        facebook_id=data.get('facebook_id', ''),
        device_token=data.get('device_token', ''),
        twitter_id=data.get('twitter_id', ''),
        manual_city=data.get('manual_city', ''),
        other_skill=data.get('other_skill', ''),
        email_verification_token=None  # No token needed
    )
    db.session.add(user)
    db.session.commit()

    # Add skills if provided
    skill_ids = data.get('aSkills', [])
    if skill_ids:
        if isinstance(skill_ids, str):
            skill_ids = [int(sid) for sid in skill_ids.split(',') if sid.strip().isdigit()]
        valid_skills = Skill.query.filter(Skill.id.in_(skill_ids)).all()
        for skill in valid_skills:
            db.session.add(UsersSkills(users_id=user.id, skills_id=skill.id))
        db.session.commit()

    # Handle profile picture upload
    profile_pic_url = None
    if 'profile_picture' in files:
        file = files['profile_picture']
        if file and allowed_file(file.filename):
            filename = secure_filename(f"user_{user.id}_{uuid.uuid4().hex}_{file.filename}")
            upload_folder = current_app.config.get('PROFILE_PIC_UPLOAD_FOLDER', 'uploads/profile_pics')
            os.makedirs(upload_folder, exist_ok=True)
            file_path = os.path.join(upload_folder, filename)
            file.save(file_path)
            profile_pic_url = url_for('static', filename=f"profile_pics/{filename}", _external=True)
            user.profile_picture_url = profile_pic_url
            db.session.commit()

    user_row = manage_user_row(user.as_dict(), user.id, level='0')
    user_row['profile_picture_url'] = profile_pic_url

    # Issue JWT token for immediate login (for iOS app)
    jwt_secret = os.environ.get('JWT_SECRET', 'changeme')
    token = jwt.encode({
        'user_id': user.id,
        'exp': datetime.datetime.utcnow() + datetime.timedelta(days=7)
    }, jwt_secret, algorithm='HS256')

    return jsonify({
        'result': 'Registration successful. You are now logged in.',
        'user': user_row,
        'token': token if isinstance(token, str) else token.decode('utf-8')
    })

@user_bp.route('/api/user/verify_email', methods=['GET'])
def api_verify_email():
    token = request.args.get('token')
    if not token:
        return jsonify({'error': 'Verification token required'}), 400
    user = User.query.filter_by(email_verification_token=token).first()
    if not user:
        return jsonify({'error': 'Invalid or expired token'}), 400
    user.confirmed = True
    user.email_verification_token = None
    db.session.commit()

    # Issue JWT token for mobile clients after verification
    jwt_secret = os.environ.get('JWT_SECRET', 'changeme')
    token = jwt.encode({
        'user_id': user.id,
        'exp': datetime.datetime.utcnow() + datetime.timedelta(days=7)
    }, jwt_secret, algorithm='HS256')

    user_row = manage_user_row(user.as_dict(), user.id, level='0')
    return jsonify({
        'result': 'Email verified successfully',
        'user_id': user.id,
        'token': token if isinstance(token, str) else token.decode('utf-8'),
        'user': user_row
        