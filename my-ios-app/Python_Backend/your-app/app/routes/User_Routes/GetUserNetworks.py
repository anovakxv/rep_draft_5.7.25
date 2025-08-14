# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app import db
from app.models.People_Models.user import User
from app.models.People_Models.UserNetwork import UserNetwork
from app.models.ValueMetric_Models.GoalTeam import GoalTeam
from app.models.People_Models.Messaging_Models.GroupChatUsers import ChatsUsers
from app.models.People_Models.Skill import Skill
from app.models.People_Models.UserSkill import UserSkill
from app.models.People_Models.UserFollower import UserFollower
from app.utils.user_utils import manage_user_row
from app.utils.auth import jwt_required

# --- S3 BASE URL ---
S3_BASE_URL = "https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/"

user_bp = Blueprint('get_user_skills', __name__)

def patch_profile_picture_url(user_row):
    url = user_row.get('profile_picture_url')
    if url and not url.startswith("http"):
        user_row['profile_picture_url'] = S3_BASE_URL + url
    if not url or str(url).strip() == "":
        user_row['profile_picture_url'] = None
    return user_row

def batch_get_skills(user_ids):
    # Fetch all skills for all users in one query
    skills = (
        db.session.query(UserSkill.users_id, Skill)
        .join(Skill, Skill.id == UserSkill.skills_id)
        .filter(UserSkill.users_id.in_(user_ids))
        .all()
    )
    skills_map = {}
    for uid, skill in skills:
        skills_map.setdefault(uid, []).append(skill.title)
    return skills_map

def batch_get_relationships(session_user_id, user_ids):
    # Fetch all relationships in one go
    i_follow = set(
        uid for uid, in db.session.query(UserFollower.users_id2)
        .filter(UserFollower.users_id1 == session_user_id, UserFollower.users_id2.in_(user_ids))
    )
    i_am_followed_by = set(
        uid for uid, in db.session.query(UserFollower.users_id1)
        .filter(UserFollower.users_id2 == session_user_id, UserFollower.users_id1.in_(user_ids))
    )
    in_my_network = set(
        uid for uid, in db.session.query(UserNetwork.users_id2)
        .filter(UserNetwork.users_id1 == session_user_id, UserNetwork.users_id2.in_(user_ids))
    )
    i_am_in_their_network = set(
        uid for uid, in db.session.query(UserNetwork.users_id1)
        .filter(UserNetwork.users_id2 == session_user_id, UserNetwork.users_id1.in_(user_ids))
    )
    rel_map = {}
    for uid in user_ids:
        rel_map[uid] = {
            "i_follow": uid in i_follow,
            "i_am_followed_by": uid in i_am_followed_by,
            "in_my_network": uid in in_my_network,
            "i_am_in_their_network": uid in i_am_in_their_network,
        }
    return rel_map

def get_user_response_batch(users, session_user_id=None, skills_map=None, rel_map=None):
    result = []
    for user in users:
        user_row = user.as_dict()
        level = '0' if session_user_id and str(session_user_id) == str(user.id) else '1'
        user_row = manage_user_row(user_row, user.id, level=level)
        # Add skills
        user_row['skills'] = skills_map.get(user.id, []) if skills_map else []
        # Add relationships if session user
        if session_user_id and rel_map:
            user_row['relationships'] = rel_map.get(user.id, {
                "i_follow": False,
                "i_am_followed_by": False,
                "in_my_network": False,
                "i_am_in_their_network": False,
            })
        # Patch profile picture URL to be full S3 URL if needed
        user_row = patch_profile_picture_url(user_row)
        result.append(user_row)
    return result

@user_bp.route('/members_of_my_network', methods=['GET'])
@jwt_required
def api_members_of_my_network():
    session_user_id = g.current_user.id
    invited_goal_id = request.args.get('invited_goal_id', type=int)
    not_in_chats_id = request.args.get('not_in_chats_id', type=int)
    keyword = request.args.get('keyword', '')

    # Always use the session user as the network owner
    users_id = session_user_id

    query = db.session.query(User).join(
        UserNetwork, UserNetwork.users_id2 == User.id
    ).filter(UserNetwork.users_id1 == users_id)

    if invited_goal_id:
        subq = db.session.query(GoalTeam.users_id2).filter(
            GoalTeam.goals_id == invited_goal_id,
            GoalTeam.confirmed == 1  # Only exclude confirmed members
        )
        query = query.filter(~User.id.in_(subq))

    if not_in_chats_id:
        subq = db.session.query(ChatsUsers.users_id).filter(ChatsUsers.chats_id == not_in_chats_id)
        query = query.filter(~User.id.in_(subq))

    if keyword:
        keyword = keyword.strip().lower()
        query = query.filter(
            (User.fname + ' ' + User.lname).ilike(f"%{keyword}%")
        )

    users = query.all()
    user_ids = [u.id for u in users]

    # Batch fetch skills and relationships
    skills_map = batch_get_skills(user_ids) if user_ids else {}
    rel_map = batch_get_relationships(users_id, user_ids) if user_ids else {}

    result = get_user_response_batch(users, users_id, skills_map, rel_map)
    return jsonify({'result': result})