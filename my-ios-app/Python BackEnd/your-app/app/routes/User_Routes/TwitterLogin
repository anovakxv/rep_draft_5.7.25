
from flask import Blueprint, request, jsonify, session, make_response
from app import db
from app.models.user import User
from app.utils.user_utils import manage_user_row
import hashlib
import os

user_bp = Blueprint('user', __name__)

@user_bp.route('/api/user/twitter_login', methods=['POST'])
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

    # Set session and cookies
    session['user_id'] = user.id
    resp = make_response()
    resp.set_cookie('uid', str(user.id), max_age=3600*24*7, path='/')
    upd_hash = hashlib.md5((user.password + str(user.id) + os.environ.get('PASS_SALT', '')).encode()).hexdigest() if user.password else ''
    resp.set_cookie('upd', upd_hash, max_age=3600*24*7, path='/')

    user_row = manage_user_row(user.as_dict(), user.id, level='0')
    resp.set_data(jsonify({'result': user_row}).get_data())
    resp.mimetype = 'application/json'
    return
    