# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app import db, socketio  # socketio imported for realtime emit
from app.models.People_Models.user import User
from app.models.People_Models.Messaging_Models.Direct_Messages import DirectMessage
from app.models.Purpose_Models.Portal import Portal
from app.utils.user_utils import does_user_block, register_new_activity
from app.utils.auth import jwt_required
from app.models.People_Models.BlockedUser import BlockedUser
from datetime import datetime

from app.utils.notifications import send_fcm_notification  
from app.utils.notifications import send_notification

user_bp = Blueprint('send_message', __name__)

@user_bp.route('/send_message', methods=['POST'])
@jwt_required
def api_send_message():
    data = request.get_json() or {}
    user_id = getattr(g, "current_user", None).id if getattr(g, "current_user", None) else None
    to_user_id = data.get('users_id')
    message_text = data.get('message')
    portals_id = data.get('portals_id', None)

    if not user_id:
        return jsonify({'error': 'Login error!'}), 401
    if not to_user_id:
        return jsonify({'error': 'users_id is empty!'}), 400
    if not message_text:
        return jsonify({'error': 'message required!'}), 400

    # Coerce to int defensively
    try:
        to_user_id = int(to_user_id)
    except Exception:
        return jsonify({'error': 'users_id must be an integer'}), 400

    if portals_id:
        portal = Portal.query.filter_by(id=portals_id).first()
        if not portal:
            return jsonify({'error': "the portal doesn't exist!"}), 404

    # Block check
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
    try:
        db.session.commit()
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to save message: {str(e)}'}), 500

    # Activity log (non-fatal)
    try:
        register_new_activity(user_id, to_user_id, "new_direct_message", 1, msg.id, "messages")
    except Exception as e:
        print(f"Activity log error: {e}")

    # Fetch sender and recipient once (reuse for FCM + socket + response)
    sender = User.query.filter_by(id=user_id).first()
    recipient = User.query.filter_by(id=to_user_id).first()

    # Push notification (FCM) — best-effort
    device_token = recipient.device_token if recipient else None
    print(f"Recipient device_token: {device_token}")
    if device_token:
        try:
            print(f"About to send notification to device_token={device_token}")
            send_notification(
                to_user_id,  # The recipient's user ID
                "direct_message",  # Notification type
                title=f"New message from {sender.full_name if sender else 'Someone'}",
                body=message_text,
                data={
                    "type": "direct_message",
                    "sender_id": user_id,
                    "message_id": msg.id
                }
            )
        except Exception as e:
            print(f"Notification error: {e}")
    else:
        print(f"No device token for user_id={to_user_id}")

    # Realtime Socket.IO notification (instant unread dot for recipient)
    # Frontend joins room "user_<userId>" after authenticating (or automatically on connect).
    try:
        payload = {
            "type": "direct_message",
            "id": msg.id,                    # alias for various consumers (iOS)
            "message_id": msg.id,
            "sender_id": user_id,
            "sender_name": sender.full_name if sender else "",
            "recipient_id": to_user_id,
            "text": msg.text,
            "timestamp": msg.created_at.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "read": "0"                      # recipient hasn't read yet
        }
        socketio.emit('direct_message_notification', payload, room=f'user_{to_user_id}')
        print(f"📣 Emitted direct_message_notification to user_{to_user_id}: {payload}")
    except Exception as e:
        # Non-fatal: we still return success for the REST send; log socket errors
        print(f"Socket emit error: {e}")

    # Response payload (sender sees own message as read)
    message_obj = {
        "id": msg.id,
        "sender_id": msg.sender_id,
        "sender_name": sender.full_name if sender else "",
        "text": msg.text,
        "timestamp": msg.created_at.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "read": "1"
    }

    return jsonify({'result': 'Message sent.', 'message': message_obj}), 200