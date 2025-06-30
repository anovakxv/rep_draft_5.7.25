# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, make_response
from app import db
from app.models.People_Models.user import User
from app.utils.user_utils import manage_user_row
import hashlib
import os
import jwt
import datetime

user_bp = Blueprint('twitter_login', __name__)

@user_bp.route('/twitter_login', methods=['POST'])
def api_twitter_login():
    data = request.get_json()
    twitter_id = data.get('twitter_id')
    email = data.get('email', '')
    fname = data.get('fname', '')
    lname = data.get('lname', '')
    device_token = data.get('device_token', '')

    if not twitter_id:
        return jsonify({'error': 'twitter_id required!'}), 400

    user = User.query.filter_by(twitter_id=twitter_id).first()

    if not user:
        # Register new user with Twitter ID
        user = User(
            twitter_id=twitter_id,
            email=email,
            fname=fname,
            lname=lname,
            device_token=device_token,
            confirmed=True
        )
        db.session.add(user)
        db.session.commit()

    # Generate JWT token
    jwt_secret = os.environ.get('JWT_SECRET', 'changeme')
    token = jwt.encode({
        'user_id': user.id,
        'exp': datetime.datetime.utcnow() + datetime.timedelta(days=7)
    }, jwt_secret, algorithm='HS256')
    if isinstance(token, bytes):
        token = token.decode('utf-8')

    user_row = manage_user_row(user.as_dict(), user.id, level='0')

    resp = make_response(jsonify({'result': user_row, 'token': token}))
    resp.set_cookie('uid', str(user.id), max_age=3600*24*7, path='/')
    upd_hash = hashlib.md5((user.password + str(user.id) + os.environ.get('PASS_SALT', '')).encode()).hexdigest() if user.password else ''
    resp.set_cookie('upd', upd_hash, max_age=3600*24*7, path='/')
    return resp
