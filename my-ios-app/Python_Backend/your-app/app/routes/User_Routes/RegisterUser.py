# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, url_for, current_app
from app import db, socketio  # CHANGED: include socketio
from app.models.People_Models.user import User
from app.models.People_Models.Skill import Skill
from app.models.People_Models.UserSkill import UserSkill
from app.utils.user_utils import check_user_data, check_new_email, manage_user_row
import hashlib
import os
import uuid
import jwt
import datetime
from werkzeug.utils import secure_filename

# Optional: welcome DM helper (best-effort, idempotent)
try:
    from app.utils.welcome_dm import send_welcome_dm_once
except Exception:
    send_welcome_dm_once = None  # type: ignore

# --- S3 BASE URL ---
S3_BASE_URL = "https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/"

user_bp = Blueprint('register_user', __name__)

def allowed_file(filename):
    allowed_extensions = {'png', 'jpg', 'jpeg', 'gif'}
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in allowed_extensions

def patch_profile_picture_url(user_row):
    url = user_row.get('profile_picture_url')
    if url and not url.startswith("http"):
        user_row['profile_picture_url'] = S3_BASE_URL + url
    if not url or str(url).strip() == "":
        user_row['profile_picture_url'] = None
    return user_row

@user_bp.route('/register', methods=['POST'])
def api_register_user():
    data = request.form.to_dict()
    files = request.files
    try:
        check_user_data(data)
    except Exception as e:
        return jsonify({'error': str(e)}), 400

    try:
        check_new_email(data['email'])
        data['username'] = data['email']
    except Exception as e:
        return jsonify({'error': str(e)}), 400

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
        username=data['email'],
        confirmed=True,
        device_token=data.get('device_token', ''),
        twitter_id=data.get('twitter_id', ''),
        manual_city=data.get('manual_city', ''),
        other_skill=data.get('other_skill', ''),
        email_verification_token=None
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
            db.session.add(UserSkill(users_id=user.id, skills_id=skill.id))
        db.session.commit()

    # Handle profile picture upload
    profile_pic_url = None
    if 'profile_picture' in files:
        file = files['profile_picture']
        if file and allowed_file(file.filename):
            filename = secure_filename(f"user_{user.id}_{uuid.uuid4().hex}_{file.filename}")
            # In production, you would upload to S3 here and set the S3 URL
            # For now, just use the filename as the key
            user.profile_picture_url = filename
            db.session.commit()
            profile_pic_url = S3_BASE_URL + filename

    user_row = manage_user_row(user.as_dict(), user.id, level='0')
    user_row = patch_profile_picture_url(user_row)
    if profile_pic_url:
        user_row['profile_picture_url'] = profile_pic_url

    jwt_secret = os.environ.get('JWT_SECRET', 'changeme')
    token = jwt.encode({
        'user_id': user.id,
        'exp': datetime.datetime.utcnow() + datetime.timedelta(days=7)
    }, jwt_secret, algorithm='HS256')

    # Best-effort Welcome DM (idempotent). Safe if helper/env not configured.
    if send_welcome_dm_once:
        try:
            send_welcome_dm_once(db, socketio, recipient_id=user.id)
        except Exception as e:
            print(f"[WelcomeDM][register] send failed: {e}")

    return jsonify({
        'result': 'Registration successful. You are now logged in.',
        'user': user_row,
        'token': token if isinstance(token, str) else token.decode('utf-8')
    })

@user_bp.route('/verify_email', methods=['GET'])
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

    jwt_secret = os.environ.get('JWT_SECRET', 'changeme')
    token = jwt.encode({
        'user_id': user.id,
        'exp': datetime.datetime.utcnow() + datetime.timedelta(days=7)
    }, jwt_secret, algorithm='HS256')

    user_row = manage_user_row(user.as_dict(), user.id, level='0')
    user_row = patch_profile_picture_url(user_row)
    return jsonify({
        'result': 'Email verified successfully',
        'user_id': user.id,
        'token': token if isinstance(token, str) else token.decode('utf-8'),
        'user': user_row
    })