# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, jsonify, g
from app import db
from app.models.People_Models.user import User
from app.models.People_Models.Skill import Skill
from app.models.People_Models.UserSkill import UserSkill
from app.models.People_Models.UserFollower import UserFollower
from app.models.People_Models.UserNetwork import UserNetwork
from app.utils.user_utils import manage_user_row
from app.utils.auth import jwt_required

# --- S3 BASE URL ---
S3_BASE_URL = "https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/"

def patch_profile_picture_url(user_row):
    url = user_row.get('profile_picture_url')
    if url and not url.startswith("http"):
        user_row['profile_picture_url'] = S3_BASE_URL + url
    if not url or str(url).strip() == "":
        user_row['profile_picture_url'] = None
    return user_row

user_bp = Blueprint('get_me', __name__)

def get_user_response(user, session_user_id=None):
    user_row = user.as_dict()
    level = '0' if session_user_id and str(session_user_id) == str(user.id) else '1'
    user_row = manage_user_row(user_row, user.id, level=level)
    # Add skills (as list of titles for frontend compatibility)
    user_skills = Skill.query.join(UserSkill, Skill.id == UserSkill.skills_id).filter(UserSkill.users_id == user.id).all()
    user_row['skills'] = [skill.title for skill in user_skills]    # Add relationships (self = always False except for self)
    user_row['relationships'] = {
        "i_follow": False,
        "i_am_followed_by": False,
        "in_my_network": False,
        "i_am_in_their_network": False
    }
    # Patch profile picture URL to be full S3 URL if needed
    user_row = patch_profile_picture_url(user_row)
    return user_row

@user_bp.route('/me', methods=['GET'])
@jwt_required
def api_user_me():
    user = g.current_user
    user_row = get_user_response(user, user.id)
    return jsonify({'result': user_row})