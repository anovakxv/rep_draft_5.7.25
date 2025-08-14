# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app import db, socketio  # <-- added socketio
from app.models.People_Models.user import User
from app.models.People_Models.Messaging_Models.Direct_Messages import DirectMessage
from app.models.Purpose_Models.Portal import Portal
from app.utils.user_utils import does_user_block, register_new_activity
from app.utils.auth import jwt_required
from app.models.People_Models.BlockedUser import BlockedUser
from datetime import datetime
from sqlalchemy import text
from app.utils.notifications import send_fcm_notification  # <-- existing import

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

    if portals_id:
        portal = Portal.query.filter_by(id=portals_id).first()
        if not portal:
            return jsonify({'error': "the portal doesn't exist!"}), 404

    if BlockedUser.query.filter_by(blocker_id=to_user_id, blocked_id=user_id).first():
        return jsonify({'error': 'blocked!'}), 403

    # Create & persist message
    msg = DirectMessage(
        sender_id=user_id,
        recipient_id=to_user_id,
        text=message_text,
        created_at=datetime.utcnow()
    )
    db.session.add(msg)
    db.session.commit()

    # Activity log
    register_new_activity(user_id, to_user_id, "new_direct_message", 1, msg.id, "messages")

    # Fetch sender once (reuse for FCM + socket + response)
    sender = User.query.filter_by(id=user_id).first()

    # Push notification (FCM)
    recipient = User.query.filter_by(id=to_user_id).first()
    device_token = recipient.device_token if recipient else None
    print(f"Recipient device_token: {device_token}")

    if device_token:
        try:
            print(f"About to send FCM notification to device_token={device_token}")
            send_fcm_notification(
                device_token,
                title=f"New message from {sender.full_name if sender else 'Someone'}",
                body=message_text,
                data={
                    "type": "direct_message",
                    "sender_id": user_id,
                    "message_id": msg.id
                }
            )
        except Exception as e:
            print(f"FCM notification error: {e}")
    else:
        print(f"No device token for user_id={to_user_id}")

    # Realtime Socket.IO notification
    # Frontend should have user join room "user_<userId>" after authenticating.
    try:
        socketio.emit(
            'direct_message_notification',
            {
                "type": "direct_message",
                "message_id": msg.id,
                "sender_id": user_id,
                "sender_name": sender.full_name if sender else "",
                "recipient_id": to_user_id,
                "text": msg.text,
                "timestamp": msg.created_at.strftime("%Y-%m-%dT%H:%M:%SZ")
            },
            room=f'user_{to_user_id}'
        )
    except Exception as e:
        print(f"Socket emit error: {e}")

    # Response payload
    message_obj = {
        "id": msg.id,
        "sender_id": msg.sender_id,
        "sender_name": sender.full_name if sender else "",
        "text": msg.text,
        "timestamp": msg.created_at.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "read": "1"
    }

    return jsonify({'result': 'Message sent.', 'message': message_obj}), 200