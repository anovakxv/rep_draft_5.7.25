# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, session
from app import db
from app.models.People_Models.user import User
from app.models.People_Models.Skill import Skill
from app.models.People_Models.UserSkill import UserSkill
from app.models.People_Models.UserFollower import UserFollower
from app.models.People_Models.UserNetwork import UserNetwork
from app.utils.user_utils import manage_user_row

user_bp = Blueprint('user', __name__)

def get_user_response(user, session_user_id=None):
    user_row = user.as_dict()
    level = '0' if session_user_id and str(session_user_id) == str(user.id) else '1'
    user_row = manage_user_row(user_row, user.id, level=level)
    # Add skills
    user_skills = Skill.query.join(UserSkill, Skill.id == UserSkill.skills_id).filter(UserSkill.users_id == user.id).all()
    user_row['skills'] = [skill.as_dict() for skill in user_skills]
    # Add relationships (self = always False except for self)
    user_row['relationships'] = {
        "i_follow": False,
        "i_am_followed_by": False,
        "in_my_network": False,
        "i_am_in_their_network": False
    }
    return user_row

@user_bp.route('/api/user/me', methods=['GET'])
def api_user_me():
    session_user_id = session.get('user_id')
    if not session_user_id:
        return jsonify({'error': 'login required!'}), 401

    user = User.query.filter_by(id=session_user_id).first()
    if not user:
        return jsonify({'error': "The user doesn't exist anymore"}), 404

    user_row = get_user_response(user, session_user_id)
    return jsonify({'result': user_row})
    