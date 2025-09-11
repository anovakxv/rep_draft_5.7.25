# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, current_app, g
from app import db
from app.models.People_Models.user import User
from app.models.People_Models.Skill import Skill
from app.models.People_Models.UserSkill import UserSkill
from app.models.People_Models.UserFollower import UserFollower
from app.models.People_Models.UserNetwork import UserNetwork
from app.utils.user_utils import check_new_email, check_new_username, manage_user_row
from app.utils.auth import jwt_required
import hashlib
import os
import uuid
from werkzeug.utils import secure_filename
import boto3

# --- S3 BASE URL ---
S3_BASE_URL = "https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/"
S3_BUCKET = "rep-app-dbbucket"

s3 = boto3.client(
    's3',
    aws_access_key_id=os.environ.get('AWS_ACCESS_KEY_ID'),
    aws_secret_access_key=os.environ.get('AWS_SECRET_ACCESS_KEY'),
    region_name=os.environ.get('AWS_DEFAULT_REGION')
)

def patch_profile_picture_url(user_row):
    url = user_row.get('profile_picture_url')
    if url and not url.startswith("http"):
        user_row['profile_picture_url'] = S3_BASE_URL + url
    if not url or str(url).strip() == "":
        user_row['profile_picture_url'] = None
    return user_row

user_bp = Blueprint('edit_user', __name__)

def allowed_file(filename):
    allowed_extensions = {'png', 'jpg', 'jpeg', 'gif'}
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in allowed_extensions

def get_user_response(user, session_user_id=None):
    user_row = user.as_dict()
    level = '0' if session_user_id and str(session_user_id) == str(user.id) else '1'
    user_row = manage_user_row(user_row, user.id, level=level)
    # Add skills
    user_skills = Skill.query.join(UserSkill, Skill.id == UserSkill.skills_id).filter(UserSkill.users_id == user.id).all()
    user_row['skills'] = [skill.title for skill in user_skills]    # Add relationships if session user
    if session_user_id:
        user_row['relationships'] = {
            "i_follow": UserFollower.query.filter_by(users_id1=session_user_id, users_id2=user.id).count() > 0,
            "i_am_followed_by": UserFollower.query.filter_by(users_id2=session_user_id, users_id1=user.id).count() > 0,
            "in_my_network": UserNetwork.query.filter_by(users_id1=session_user_id, users_id2=user.id).count() > 0,
            "i_am_in_their_network": UserNetwork.query.filter_by(users_id2=session_user_id, users_id1=user.id).count() > 0,
        }
    # Patch profile picture URL to be full S3 URL if needed
    user_row = patch_profile_picture_url(user_row)
    return user_row

@user_bp.route('/edit', methods=['POST'])
@jwt_required
def api_edit_user():
    # Accept both JSON and multipart/form-data for profile picture upload
    if request.content_type and request.content_type.startswith('multipart/form-data'):
        data = request.form.to_dict()
        files = request.files
    else:
        data = request.get_json()
        files = {}

    user = g.current_user
    user_id = user.id

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
            file.seek(0)
            s3.upload_fileobj(file, S3_BUCKET, filename)
            user.profile_picture_url = filename

    db.session.commit()

    # Skills update
    if data.get('aSkills') is not None:
        UserSkill.query.filter_by(users_id=user.id).delete()
        skill_ids = data['aSkills']
        if isinstance(skill_ids, str):
            skill_ids = [int(sid) for sid in skill_ids.split(',') if sid.strip().isdigit()]
        valid_skills = Skill.query.filter(Skill.id.in_(skill_ids)).all()
        for skill in valid_skills:
            db.session.add(UserSkill(users_id=user.id, skills_id=skill.id))
        db.session.commit()

    # Return updated user profile with skills and relationships
    return jsonify({'result': get_user_response(user, session_user_id=user_id)})

@user_bp.route('/delete', methods=['POST'])
@jwt_required
def api_delete_user():
    user = g.current_user
    user_id = user.id

    # Delete related UserSkill, UserNetwork, UserFollower
    UserSkill.query.filter_by(users_id=user_id).delete()
    UserNetwork.query.filter((UserNetwork.users_id1 == user_id) | (UserNetwork.users_id2 == user_id)).delete()
    UserFollower.query.filter((UserFollower.users_id1 == user_id) | (UserFollower.users_id2 == user_id)).delete()

    # Delete related Write sections
    from app.models.People_Models.Write_Models.Writings_Model import Write
    Write.query.filter_by(users_id=user_id).delete()

    # Delete Goals where user is the creator
    from app.models.ValueMetric_Models.Goal import Goal
    Goal.query.filter_by(users_id=user_id).delete()

    # Delete Portals where user is the creator
    from app.models.Purpose_Models.Portal import Portal
    Portal.query.filter_by(users_id=user_id).delete()

    # Remove user from PortalUser/team member relationships (do not delete the portal)
    from app.models.Purpose_Models.PortalUser import PortalUser
    PortalUser.query.filter_by(user_id=user_id).delete()

    # Delete related DirectMessages (sent or received)
    from app.models.People_Models.Messaging_Models.Direct_Messages import DirectMessage
    DirectMessage.query.filter((DirectMessage.sender_id == user_id) | (DirectMessage.recipient_id == user_id)).delete()

    from app.models.ValueMetric_Models.GoalProgressLog import GoalProgressLog
    GoalProgressLog.query.filter_by(users_id=user_id).delete()

    # Add any other related deletes here as needed

    db.session.delete(user)
    db.session.commit()
    return jsonify({'result': 'ok'})

@user_bp.route('/notification_settings', methods=['PATCH'])
@jwt_required
def update_notification_settings():
    user_id = g.current_user.id
    data = request.json or {}

    user = db.session.query(User).filter_by(id=user_id).first()
    if not user:
        return jsonify({'error': 'User not found'}), 404

    # Store notification settings in user.notification_settings JSON field
    if not hasattr(user, 'notification_settings'):
        # If User model doesn't have notification_settings field yet, 
        # you'll need to add it via migration
        return jsonify({'message': 'Notification settings will be added in a future update'}), 200

    user.notification_settings = data
    db.session.commit()
    
    return jsonify({'message': 'Notification settings updated successfully'})
