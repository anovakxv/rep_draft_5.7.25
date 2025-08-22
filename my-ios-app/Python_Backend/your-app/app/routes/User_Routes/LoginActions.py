# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, session, make_response
from app import db, socketio  # CHANGED: include socketio for realtime emit
from app.models.People_Models.user import User
from app.models.People_Models.PasswordUpdater import PasswordUpdater
from app.utils.user_utils import manage_user_row, mark_all_activities_as_read
from app.utils.mail_utils import send_mail
import hashlib
import os
import jwt
import datetime
import time

# Optional: welcome DM helper (best-effort, idempotent)
try:
    from app.utils.welcome_dm import send_welcome_dm_once
except Exception:
    send_welcome_dm_once = None  # type: ignore

user_bp = Blueprint('login_user', __name__)

@user_bp.route('/login', methods=['POST'])
def api_login_user():
    data = request.get_json()
    email = data.get('email', '').strip()
    username = data.get('username', '').strip()
    password = data.get('password', '')

    if not (email or username) or not password:
        return jsonify({'error': 'empty Email or Password'}), 400

    user = None
    if email:
        user = User.query.filter_by(email=email).first()
    elif username:
        user = User.query.filter_by(username=username).first()

    if not user or not user.password:
        return jsonify({'error': 'Invalid email/username or password'}), 401

    expected_hash = hashlib.md5((os.environ['PASS_SALT'] + password).encode()).hexdigest()
    if user.password != expected_hash:
        return jsonify({'error': 'Invalid email/username or password'}), 401

    if hasattr(user, 'confirmed') and not user.confirmed:
        return jsonify({'error': 'Please verify your email before logging in.'}), 403

    session['user_id'] = user.id

    jwt_secret = os.environ.get('JWT_SECRET', 'changeme')
    token = jwt.encode({
        'user_id': user.id,
        'exp': datetime.datetime.utcnow() + datetime.timedelta(days=7)
    }, jwt_secret, algorithm='HS256')

    # If using PyJWT >= 2.0, jwt.encode returns a bytes object, so decode to str
    if isinstance(token, bytes):
        token = token.decode('utf-8')

    user_row = manage_user_row(user.as_dict(), user.id, level='0')
    mark_all_activities_as_read(user.id)

    resp = make_response(jsonify({'result': user_row, 'token': token}))
    resp.set_cookie('uid', str(user.id), max_age=60*60*24*30, path='/')
    resp.set_cookie('upd', str(datetime.datetime.utcnow().timestamp()), max_age=60*60*24*30, path='/')

    # Fire-and-forget Welcome DM (idempotent). Safe if helper/env not configured.
    if send_welcome_dm_once:
        try:
            send_welcome_dm_once(db, socketio, recipient_id=user.id)
        except Exception as e:
            print(f"[WelcomeDM][login] send failed: {e}")

    return resp

@user_bp.route('/logout', methods=['POST'])
def api_logout_user():
    session.pop('user_id', None)
    resp = make_response(jsonify({'result': 'ok'}))
    resp.set_cookie('upd', '', expires=0, path='/')
    resp.set_cookie('uid', '', expires=0, path='/')
    return resp

@user_bp.route('/forgot_password', methods=['POST'])
def api_forgot_password():
    import time
    from datetime import datetime, timedelta

    data = request.get_json()
    email = data.get('email', '')
    hash_val = data.get('hash', '')
    new_password = data.get('new_password', '')

    PASS_SALT = os.environ.get('PASS_SALT', '')

    # Step 1: Request password reset (send hash)
    if email and not hash_val:
        user = User.query.filter_by(email=email).first()
        if not user:
            return jsonify({'error': "That user doesn't exist!"}), 404

        # Remove any old hashes for this user
        PasswordUpdater.query.filter_by(users_id=user.id).delete()

        # Create a new hash
        hash_str = hashlib.md5(f"{user.id}{user.password}{PASS_SALT}{str(time.time())}".encode()).hexdigest()
        updater = PasswordUpdater(users_id=user.id, hash=hash_str)
        db.session.add(updater)
        db.session.commit()

        reset_link = f"https://networkedcapital.co/reset_password/?token={hash_str}"
        message = f"""
Hello,<br><br>
We received a request to reset your password.<br><br>
Click the link below to set a new password:<br>
<a href="{reset_link}">{reset_link}</a><br><br>
If you did not request this, you can ignore this email.<br><br>
Thanks,<br>
The Networked Capital Team
"""

        send_mail(email, 'Reset your password', message, from_email='repcontact2025@gmail.com')
        return jsonify({'result': 'sent'})

    # Step 2: Reset password using hash
    if hash_val:
        updater = PasswordUpdater.query.filter_by(hash=hash_val).first()
        if not updater:
            return jsonify({'error': 'Invalid or expired reset link.'}), 400

        if not new_password:
            return jsonify({'error': 'New password required.'}), 400

        user = User.query.filter_by(id=updater.users_id).first()
        if not user:
            db.session.delete(updater)
            db.session.commit()
            return jsonify({'error': "User not found"}), 404

        user.password = hashlib.md5((PASS_SALT + new_password).encode()).hexdigest()
        db.session.delete(updater)
        db.session.commit()
        return jsonify({'result': 'ok'})

    return jsonify({'error': 'email or (hash and new_password) required!'}), 400