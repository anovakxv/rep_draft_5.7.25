# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app import db
from app.models.People_Models.Messaging_Models.Direct_Messages import DirectMessage
from app.utils.auth import jwt_required

user_bp = Blueprint('delete_message', __name__)

@user_bp.route('/delete_message', methods=['POST'])
@jwt_required
def api_delete_message():
    data = request.get_json()
    user_id = g.current_user.id
    messages_id = data.get('messages_id')
    users_id = data.get('users_id')

    if not user_id:
        return jsonify({'error': 'Login error!'}), 401
    if not messages_id and not users_id:
        return jsonify({'error': 'messages_id AND users_id are empty!'}), 400
    if messages_id and users_id:
        return jsonify({'error': 'messages_id OR users_id required, not both!'}), 400

    aLog = []

    if messages_id:
        # Delete a single direct message if the user is a participant
        msg = DirectMessage.query.filter(
            DirectMessage.id == messages_id,
            ((DirectMessage.sender_id == user_id) | (DirectMessage.recipient_id == user_id))
        ).first()
        if msg:
            db.session.delete(msg)
            db.session.commit()
            aLog.append(f"{msg.id}; S3: ")
    elif users_id:
        # Delete all direct messages between the two users
        msgs = DirectMessage.query.filter(
            ((DirectMessage.sender_id == user_id) & (DirectMessage.recipient_id == users_id)) |
            ((DirectMessage.recipient_id == user_id) & (DirectMessage.sender_id == users_id))
        ).all()
        for msg in msgs:
            db.session.delete(msg)
            aLog.append(f"{msg.id}; S3: ")
        db.session.commit()

    return jsonify({'result': 'messages deleted', 'log': aLog})
