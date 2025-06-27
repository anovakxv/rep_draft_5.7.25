# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, session
from app import db
from app.models.People_Models.Messaging_Models.Group_Messages import GroupMessage
from app.models.People_Models.Messaging_Models.GroupChatMetaData import Chats
from app.models.portal import Portal
from datetime import datetime

user_bp = Blueprint('user', __name__)

@user_bp.route('/api/user/send_chat_message', methods=['POST'])
def api_send_chat_message():
    data = request.get_json()
    user_id = session.get('user_id')
    chat_id = data.get('chats_id')
    message_text = data.get('message')
    portals_id = data.get('portals_id', None)

    if not user_id:
        return jsonify({'error': 'Login error!'}), 401
    if not chat_id:
        return jsonify({'error': 'chats_id is empty!'}), 400
    if not message_text:
        return jsonify({'error': 'message required!'}), 400

    # Optional: Check if portal exists
    if portals_id:
        portal = Portal.query.filter_by(id=portals_id).first()
        if not portal:
            return jsonify({'error': "the portal doesn't exist!"}), 404

    # Check if chat exists
    chat = Chats.query.filter_by(id=chat_id).first()
    if not chat:
        return jsonify({'error': "the chat doesn't exist!"}), 404

    # Create group message
    msg = GroupMessage(
        chat_id=chat_id,
        sender_id=user_id,
        text=message_text,
        created_at=datetime.utcnow()
    )
    db.session.add(msg)
    db.session.commit()

    # Optionally, remove hidden chat conversations
    db.session.execute(
        "DELETE FROM chats_hidden_conversations WHERE chats_id=:cid",
        {'cid': chat_id}
    )
    db.session.commit()

    # Use as_dict() for unified response, includes sender user object
    message_obj = msg.as_dict()
