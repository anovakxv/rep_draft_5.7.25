from flask import Blueprint, request, jsonify, session, make_response
from app import db
from app.models.user import User
from app.models.password_updaters import PasswordUpdaters
from app.utils.user_utils import manage_user_row, mark_all_activities_as_read
from app.utils.mail_utils import send_mail  # Make sure this utility exists
import hashlib
import os
import jwt
import datetime
import time

user_bp = Blueprint('user', __name__)

@user_bp.route('/api/user/login', methods=['POST'])
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

    # Set session and cookies
    session['user_id'] = user.id

    jwt_secret = os.environ.get('JWT_SECRET', 'changeme')
    token = jwt.encode({
        'user_id': user.id,
        'exp': datetime.datetime.utcnow() + datetime.timedelta(days=7)
    }, jwt_secret, algorithm='HS256')

    user_row = manage_user_row(user.as_dict(), user.id, level='0')
    mark_all_activities_as_read(user.id)

    resp = make_response(jsonify({'result': user_row, 'token': token}))
    resp.set_cookie('uid', str(user.id), max_age=60*60*24*30, path='/')
    resp.set_cookie('upd', str(datetime.datetime.utcnow().timestamp()), max_age=60*60*24*30, path='/')
    return resp

@user_bp.route('/api/user/logout', methods=['POST'])
def api_logout_user():
    session.pop('user_id', None)
    resp = make_response(jsonify({'result': 'ok'}))
    resp.set_cookie('upd', '', expires=0, path='/')
    resp.set_cookie('uid', '', expires=0, path='/')
    return resp

@user_bp.route('/api/user/forgot_password', methods=['POST'])
def api_forgot_password():
    data = request.get_json()
    email = data.get('email', '')
    hash_val = data.get('hash', '')
    new_password = data.get('new_password', '')

    PASS_SALT = os.environ.get('PASS_SALT', '')

    if not email and not hash_val:
        return jsonify({'error': 'email or (hash and/or new_password) required!'}), 400

    # Step 1: Request password reset (send hash)
    if not hash_val:
        user = User.query.filter_by(email=email).first()
        if not user:
            return jsonify({'error': "that user doesn't exist!"}), 404

        hash_str = hashlib.md5(f"{user.id}{user.password}{PASS_SALT}".encode()).hexdigest()
        updater = PasswordUpdaters(users_id=user.id, hash=hash_str)
        db.session.add(updater)
        db.session.commit()

        reset_link = f"https://yourdomain.com/reset_password/{hash_str}/"
        message = f"Your hash is {hash_str}; the link to reset your password is {reset_link} account: {email}."
        send_mail(email, 'Reset your password', message)
        return jsonify({'result': 'sent'})

    # Step 2: Reset password using hash
    updater = PasswordUpdaters.query.filter_by(hash=hash_val).first()
    if not updater:
        return jsonify({'error': 'wrong hash'}), 400

    show_new_password = False
    if not new_password:
        # Generate a new password if not provided
        new_password = (
            hashlib.md5((PASS_SALT + str(time.time())).encode()).hexdigest()[2:10]
            + '_' + hash_val[2:10]
        )
        show_new_password = True

    user = User.query.filter_by(id=updater.users_id).first()
    if not user:
        return jsonify({'error': "User not found"}), 404

    user.password = hashlib.md5((PASS_SALT + new_password).encode()).hexdigest()
    db.session.delete(updater)
    db.session.commit()

    if show_new_password:
        return jsonify({'new_password': new_password})
    return jsonify({'result': 'ok'})
