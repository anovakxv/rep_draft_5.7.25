# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app import db
from app.models.People_Models.Messaging_Models.GroupChatMetaData import Chats
from app.models.People_Models.Messaging_Models.GroupChatUsers import ChatsUsers
from app.utils.auth import jwt_required

user_bp = Blueprint('delete_chat', __name__)

@user_bp.route('/delete_chat', methods=['POST'])
@jwt_required
def api_delete_chat():
    data = request.get_json()
    user_id = g.current_user.id
    chats_id = data.get('chats_id')

    if not user_id:
        return jsonify({'error': 'login required!'}), 401
    if not chats_id:
        return jsonify({'error': 'chats_id required!'}), 400

    chat = Chats.query.filter_by(id=chats_id).first()
    if not chat:
        return jsonify({'error': 'chat not found'}), 404

    # Permission to delete:
    #  - Goal Team chats: only the Goal's creator (goal.users_id). NOT whoever happened to
    #    create the chat row — lazy chat creation (on join, or the first "Message Team" tap)
    #    can make any member the chat's created_by, so created_by is not a reliable owner.
    #  - Regular group chats: the chat creator, as before.
    from app.models.ValueMetric_Models.Goal import Goal
    team_goal = Goal.query.filter_by(chats_id=chats_id).first()
    if team_goal:
        if user_id != team_goal.users_id:
            return jsonify({'error': 'Only the Goal Team creator can delete this chat'}), 403
    elif chat.created_by != user_id:
        return jsonify({'error': 'Only the chat creator can delete this chat'}), 403

    # Delete chat and related data. Unlink the goal first so it's never left pointing at a
    # deleted chat (belt-and-suspenders alongside the FK's ON DELETE SET NULL).
    if team_goal:
        team_goal.chats_id = None
    ChatsUsers.query.filter_by(chats_id=chats_id).delete()
    db.session.delete(chat)
    db.session.commit()

    return jsonify({'result': 'chat deleted'})
