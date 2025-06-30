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

    # Check if user is a member of the chat
    is_member = ChatsUsers.query.filter_by(chats_id=chats_id, users_id=user_id).count()
    if not is_member:
        # Check if user is the chat creator
        if chat.created_by != user_id:
            return jsonify({'error': 'Not authorized'}), 403

    # Delete chat and related data
    ChatsUsers.query.filter_by(chats_id=chats_id).delete()
    db.session.delete(chat)
    db.session.commit()

    return jsonify({'result': 'chat deleted'})
