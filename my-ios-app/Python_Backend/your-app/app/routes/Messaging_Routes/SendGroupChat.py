# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from operator import ne
from flask import Blueprint, request, jsonify, g
from app import db
from app.models.People_Models.Messaging_Models.Group_Messages import GroupMessage
from app.models.People_Models.Messaging_Models.GroupChatMetaData import Chats
from app.models.People_Models.Messaging_Models.GroupChatUsers import ChatsUsers
from app.models.People_Models.user import User
from app.models.Purpose_Models.Portal import Portal
from app.utils.auth import jwt_required
from app.utils.notifications import send_fcm_notification
from datetime import datetime
from app.utils.notifications import send_notification

user_bp = Blueprint('send_group_chat', __name__)

@user_bp.route('/send_chat_message', methods=['POST'])
@jwt_required
def api_send_chat_message():
    data = request.get_json()
    user_id = g.current_user.id
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

    # Check if user is a member of the chat
    is_member = ChatsUsers.query.filter_by(chats_id=chat_id, users_id=user_id).count()
    if not is_member:
        return jsonify({'error': 'You are not a member of this chat.'}), 403

    # Create group message
    msg = GroupMessage(
        chat_id=chat_id,
        sender_id=user_id,
        text=message_text,
        created_at=datetime.utcnow()
    )
    db.session.add(msg)
    db.session.commit()

    # Get sender object for notifications and response
    sender = User.query.filter_by(id=user_id).first()

    # Push notifications to other members
    try:
        member_ids = [cu.users_id for cu in ChatsUsers.query.filter_by(chats_id=chat_id).all()]
        if member_ids:
            chat_name = chat.name
            for uid in member_ids:
                if uid == user_id:
                    continue
                u = User.query.filter_by(id=uid).first()
                if not u or not u.device_token:
                    continue
                try:
                    send_notification(
                        uid,  # The recipient's user ID
                        "group_message",  # Notification type
                        title=f"{sender.full_name if sender else 'Someone'} in {chat_name}",
                        body=message_text,
                        data={
                            "type": "group_message",
                            "chat_id": chat_id,
                            "message_id": msg.id,
                            "sender_id": user_id
                        }
                    )
                except Exception as ne:
                    print(f"[GroupChat Notification] Error sending to user {uid}: {ne}")
    except Exception as e:
        print(f"[GroupChat FCM] Block error: {e}")

    # Prepare response matching Swift GroupMessage model
    message_obj = {
        "id": msg.id,
        "sender_id": msg.sender_id,
        "sender_name": sender.full_name if sender else "",
        "sender_photo_url": getattr(sender, "profile_picture_url", None) if sender else None,
        "text": msg.text,
        "timestamp": msg.created_at.strftime("%Y-%m-%dT%H:%M:%SZ")
    }

    # --- Socket.IO broadcast for real-time group chat ---
    try:
        from app import socketio
        print(f"[SocketIO] Emitting group_message to chat_{chat_id}: {message_obj}")
        socketio.emit(
            "group_message",
            {"chat_id": chat_id, **message_obj},
            room=f"chat_{chat_id}"
        )
        # NEW: also notify each member's personal room for OPEN dot
        try:
            member_ids = [cu.users_id for cu in ChatsUsers.query.filter_by(chats_id=chat_id).all()]
        except Exception:
            member_ids = []
        notif_payload = {
            "type": "group_message",
            "chat_id": chat_id,
            "message_id": msg.id,
            "sender_id": user_id,
            "text": msg.text,
            "timestamp": msg.created_at.strftime("%Y-%m-%dT%H:%M:%SZ")
        }
        for uid in member_ids:
            if uid == user_id:
                continue
            socketio.emit("group_message_notification", notif_payload, room=f"user_{uid}")
    except Exception as e:
        # Log error but do not block response
        print(f"SocketIO emit error: {e}")

    return jsonify({'result': 'Message sent.', 'message': message_obj}), 200