# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app import db
from app.models.People_Models.user import User
from app.models.People_Models.Messaging_Models.Direct_Messages import DirectMessage
from app.models.Purpose_Models.Portal import Portal
from app.utils.user_utils import does_user_block, register_new_activity
from app.utils.auth import jwt_required
from datetime import datetime
from sqlalchemy import text

user_bp = Blueprint('send_message', __name__)

@user_bp.route('/send_message', methods=['POST'])
@jwt_required
def api_send_message():
    data = request.get_json()
    user_id = g.current_user.id
    to_user_id = data.get('users_id')
    message_text = data.get('message')
    portals_id = data.get('portals_id', None)

    if not user_id:
        return jsonify({'error': 'Login error!'}), 401
    if not to_user_id:
        return jsonify({'error': 'users_id is empty!'}), 400
    if not message_text:
        return jsonify({'error': 'message required!'}), 400

    # Optional: Check if portal exists
    if portals_id:
        portal = Portal.query.filter_by(id=portals_id).first()
        if not portal:
            return jsonify({'error': "the portal doesn't exist!"}), 404

    # Check if blocked
    if does_user_block(to_user_id, user_id):
        return jsonify({'error': 'blocked!'}), 403

    # Create message using DirectMessage model
    msg = DirectMessage(
        sender_id=user_id,
        recipient_id=to_user_id,
        text=message_text,
        created_at=datetime.utcnow()
    )
    db.session.add(msg)
    db.session.commit()

    # Register activity
    register_new_activity(user_id, to_user_id, "new_direct_message", 1, msg.id, "messages")

    # Optionally, remove hidden conversations
    # db.session.execute(
    #    text(
    #        "DELETE FROM users_hidden_conversations WHERE "
    #        "   (users_id1=:uid1 AND users_id2=:uid2) OR (users_id2=:uid1 AND users_id1=:uid2)"
    #    ),
    #    {'uid1': user_id, 'uid2': to_user_id}
    #)
    #db.session.commit()

    # Build flat message object for Swift client
    sender = User.query.filter_by(id=user_id).first()
    message_obj = {
        "id": msg.id,
        "sender_id": msg.sender_id,
        "sender_name": sender.full_name if sender else "",
        "text": msg.text,
        "timestamp": msg.created_at.isoformat() + "Z"
    }

    return jsonify({'result': 'Message sent.', 'message': message_obj}), 200