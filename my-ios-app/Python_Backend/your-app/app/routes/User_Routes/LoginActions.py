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

        # Create a new hash with timestamp for expiration
        hash_str = hashlib.md5(f"{user.id}{user.password}{PASS_SALT}{str(time.time())}".encode()).hexdigest()
        updater = PasswordUpdater(users_id=user.id, hash=hash_str, timestamp=datetime.utcnow())
        db.session.add(updater)
        db.session.commit()

        reset_link = f"https://www.repsomething.com/new-password?hash={hash_str}"
        message = f"""
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #f5f5f5;">
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
        <tr>
            <td align="center" style="padding: 40px 20px;">
                <table role="presentation" width="600" cellspacing="0" cellpadding="0" border="0" style="max-width: 600px; background-color: #ffffff; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
                    <!-- Header -->
                    <tr>
                        <td style="padding: 40px 40px 20px; text-align: center;">
                            <h1 style="margin: 0; color: #8cc65d; font-size: 32px; font-weight: bold;">Rep</h1>
                        </td>
                    </tr>

                    <!-- Content -->
                    <tr>
                        <td style="padding: 20px 40px 40px;">
                            <h2 style="margin: 0 0 20px; color: #333333; font-size: 24px; font-weight: 600;">Reset Your Password</h2>
                            <p style="margin: 0 0 20px; color: #666666; font-size: 16px; line-height: 24px;">
                                We received a request to reset your password. Click the button below to create a new password:
                            </p>

                            <!-- Button -->
                            <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
                                <tr>
                                    <td align="center" style="padding: 20px 0;">
                                        <a href="{reset_link}" style="display: inline-block; padding: 14px 32px; background-color: #8cc65d; color: #ffffff; text-decoration: none; border-radius: 8px; font-size: 16px; font-weight: 600;">Reset Password</a>
                                    </td>
                                </tr>
                            </table>

                            <p style="margin: 20px 0 0; color: #666666; font-size: 14px; line-height: 20px;">
                                Or copy and paste this link into your browser:
                            </p>
                            <p style="margin: 8px 0 0; color: #8cc65d; font-size: 14px; word-break: break-all;">
                                {reset_link}
                            </p>

                            <p style="margin: 30px 0 0; color: #999999; font-size: 14px; line-height: 20px;">
                                <strong>This link will expire in 1 hour.</strong>
                            </p>

                            <p style="margin: 20px 0 0; color: #999999; font-size: 14px; line-height: 20px;">
                                If you didn't request this password reset, you can safely ignore this email. Your password will not be changed.
                            </p>
                        </td>
                    </tr>

                    <!-- Footer -->
                    <tr>
                        <td style="padding: 30px 40px; background-color: #f9f9f9; border-top: 1px solid #eeeeee; border-radius: 0 0 8px 8px;">
                            <p style="margin: 0; color: #999999; font-size: 12px; line-height: 18px; text-align: center;">
                                © 2025 Rep. All rights reserved.<br>
                                <a href="https://www.repsomething.com" style="color: #8cc65d; text-decoration: none;">www.repsomething.com</a>
                            </p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
"""

        send_mail(email, 'Reset your password', message, from_email='contact@repsomething.com')
        return jsonify({'result': 'sent'})

    # Step 2: Reset password using hash
    if hash_val:
        updater = PasswordUpdater.query.filter_by(hash=hash_val).first()
        if not updater:
            return jsonify({'error': 'Invalid or expired reset link.'}), 400

        # Check if token is expired (1 hour expiration)
        if updater.timestamp:
            token_age = datetime.utcnow() - updater.timestamp
            if token_age > timedelta(hours=1):
                db.session.delete(updater)
                db.session.commit()
                return jsonify({'error': 'Reset link has expired. Please request a new one.'}), 400

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