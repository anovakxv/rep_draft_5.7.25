# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify
from app import db
from app.models.People_Models.user import User
from app.models.People_Models.UserNetwork import UserNetwork
from app.models.ValueMetric_Models.GoalTeam import GoalTeam
from app.models.People_Models.Messaging_Models.GroupChatUsers import ChatsUsers
from app.utils.user_utils import manage_user_row

user_bp = Blueprint('user', __name__)

@user_bp.route('/api/user/members_of_my_network', methods=['GET'])
def api_members_of_my_network():
    users_id = request.args.get('users_id', type=int)
    invited_goal_id = request.args.get('invited_goal_id', type=int)
    not_in_chats_id = request.args.get('not_in_chats_id', type=int)
    keyword = request.args.get('keyword', '')

    if not users_id:
        return jsonify({'error': 'users_id is empty!'}), 400

    query = db.session.query(User).join(
        UserNetwork, UserNetwork.users_id2 == User.id
    ).filter(UserNetwork.users_id1 == users_id)

    if invited_goal_id:
        subq = db.session.query(GoalTeam.users_id2).filter(GoalTeam.goals_id == invited_goal_id)
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
    result = [manage_user_row(u.as_dict(), users_id) for u in users]
    return
