# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app import db
from app.models.People_Models.Messaging_Models.GroupChatMetaData import Chats
# from app.models.chats_hidden_conversations import ChatsHiddenConversations
from app.utils.auth import jwt_required

user_bp = Blueprint('hide_chat_convo', __name__)

@user_bp.route('/hide_chat_conversation', methods=['POST'])
@jwt_required
def api_hide_chat_conversation():
    data = request.get_json()
    user_id = g.current_user.id
    chats_id = data.get('chats_id')
    todo = data.get('todo')

    if not user_id:
        return jsonify({'error': 'Login error!'}), 401
    if not chats_id:
        return jsonify({'error': 'chats_id is empty!'}), 400
    if not todo or todo not in ['hide', 'show']:
        return jsonify({'error': "todo is empty or wrong! Supported: hide, show"}), 400

    chat = Chats.query.filter_by(id=chats_id).first()
    if not chat:
        return jsonify({'error': "chat not found"}), 404

    exists = ChatsHiddenConversations.query.filter_by(users_id=user_id, chats_id=chats_id).first()

    if todo == 'hide':
        if exists:
            return jsonify({'error': f"You are already hiding '{chats_id}'"}), 400
        hidden = ChatsHiddenConversations(users_id=user_id, chats_id=chats_id)
        db.session.add(hidden)
        db.session.commit()
        return jsonify({'result': f"Chat '{chats_id}' hidden."})
    elif todo == 'show':
        if not exists:
            return jsonify({'error': f"You are not hiding '{chats_id}'"}), 400
        db.session.delete(exists)
        db.session.commit()
        return jsonify({'result': f"Chat '{chats_id}' shown."})
    