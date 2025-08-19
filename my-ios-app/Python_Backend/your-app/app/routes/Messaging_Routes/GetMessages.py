# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from datetime import datetime
from sqlalchemy import or_, and_
from app import db, socketio
from app.utils.auth import jwt_required
from app.utils.user_utils import register_new_activity
from app.utils.notifications import send_fcm_notification
from app.models.People_Models.user import User
from app.models.People_Models.BlockedUser import BlockedUser
from app.models.Purpose_Models.Portal import Portal
from app.models.People_Models.Messaging_Models.Direct_Messages import DirectMessage
from app.models.People_Models.Messaging_Models.messages_read import MessagesRead

user_bp = Blueprint('direct_messages', __name__)

# ---------------------------------------------------------------------------
# SEND DIRECT MESSAGE
# ---------------------------------------------------------------------------
@user_bp.route('/send_message', methods=['POST'])
@jwt_required
def api_send_message():
    data = request.get_json() or {}
    user_id = g.current_user.id
    to_user_id = data.get('users_id')
    message_text = data.get('message')
    portals_id = data.get('portals_id')

    if not to_user_id:
        return jsonify({'error': 'users_id is empty!'}), 400
    if not message_text:
        return jsonify({'error': 'message required!'}), 400

    if portals_id:
        portal = Portal.query.filter_by(id=portals_id).first()
        if not portal:
            return jsonify({'error': "the portal doesn't exist!"}), 404

    # Block check (recipient blocking sender)
    if BlockedUser.query.filter_by(blocker_id=to_user_id, blocked_id=user_id).first():
        return jsonify({'error': 'blocked!'}), 403

    # Persist message
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

    sender = User.query.filter_by(id=user_id).first()
    recipient = User.query.filter_by(id=to_user_id).first()

    # Push notification (FCM) – unchanged structure
    device_token = recipient.device_token if recipient else None
    if device_token:
        try:
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

    # Socket.IO realtime emit (room user_<recipientId>)
    try:
        socketio.emit(
            'direct_message_notification',
            {
                "type": "direct_message",
                "id": msg.id,
                "message_id": msg.id,
                "sender_id": user_id,
                "sender_name": sender.full_name if sender else "",
                "recipient_id": to_user_id,
                "text": msg.text,
                "timestamp": msg.created_at.strftime("%Y-%m-%dT%H:%M:%SZ"),
                "read": "0"  # not yet read by recipient
            },
            room=f'user_{to_user_id}'
        )
    except Exception as e:
        print(f"Socket emit error: {e}")

    # Response (sender perspective – treat as read locally)
    message_obj = {
        "id": msg.id,
        "sender_id": msg.sender_id,
        "sender_name": sender.full_name if sender else "",
        "text": msg.text,
        "timestamp": msg.created_at.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "read": "1"
    }
    return jsonify({'result': 'Message sent.', 'message': message_obj}), 200


# ---------------------------------------------------------------------------
# GET DIRECT MESSAGES (Fixed to always include most recent slice)
# ---------------------------------------------------------------------------
@user_bp.route('/get_messages', methods=['GET'])
@jwt_required
def api_get_messages():
    """
    Fetch last N direct messages between current user and users_id.
    Query params:
      users_id    (required) other participant
      limit       (optional, default 200, max 500)
      order       ASC|DESC presentation order (default ASC)
      before_id   (optional) paginate older history (messages with id < before_id)
      mark_as_read=1 mark returned inbound (to current user) messages as read
    Always retrieves newest messages first internally, avoiding the old issue
    where oldest N were returned and newest were excluded when limit applied.
    """
    other_id = request.args.get('users_id', type=int)
    if not other_id:
        return jsonify({'error': 'users_id required'}), 400

    current_id = g.current_user.id
    limit = request.args.get('limit', type=int) or 200
    if limit < 1:
        limit = 50
    limit = min(limit, 500)

    order = (request.args.get('order') or 'ASC').upper()
    if order not in ('ASC', 'DESC'):
        order = 'ASC'

    before_id = request.args.get('before_id', type=int)
    mark_flag = request.args.get('mark_as_read') == '1'

    # Conversation filter
    q = DirectMessage.query.filter(
        or_(
            and_(DirectMessage.sender_id == current_id, DirectMessage.recipient_id == other_id),
            and_(DirectMessage.sender_id == other_id, DirectMessage.recipient_id == current_id)
        )
    )
    if before_id:
        # Only messages older than the reference id
        q = q.filter(DirectMessage.id < before_id)

    # Always pull latest first (created_at DESC, id DESC for tie-break)
    q = q.order_by(DirectMessage.created_at.desc(), DirectMessage.id.desc()).limit(limit)
    recent_desc = q.all()

    read_ids_new = []

    if mark_flag and recent_desc:
        # Determine which returned messages are inbound and not already marked
        message_ids = [m.id for m in recent_desc if m.recipient_id == current_id]
        if message_ids:
            existing_marked = set(
                mid for (mid,) in db.session.query(MessagesRead.messages_id)
                .filter(MessagesRead.users_id == current_id,
                        MessagesRead.messages_id.in_(message_ids))
                .all()
            )
            for mid in message_ids:
                if mid not in existing_marked:
                    db.session.add(MessagesRead(users_id=current_id, messages_id=mid))
                    read_ids_new.append(mid)
            if read_ids_new:
                try:
                    db.session.commit()
                except Exception as e:
                    db.session.rollback()
                    print(f"Commit error marking messages read: {e}")
        else:
            existing_marked = set()
    else:
        existing_marked = set()

    # Helper: compute read state for each message from perspective of current user
    def compute_read(m: DirectMessage) -> str:
        if m.sender_id == current_id:
            return "1"  # Sent messages always shown as read for sender
        if m.id in read_ids_new or m.id in existing_marked:
            return "1"
        return "0"

    # Presentation order
    if order == 'ASC':
        ordered = list(reversed(recent_desc))
    else:
        ordered = recent_desc

    payload = [m.as_dict(read=compute_read(m)) for m in ordered]

    return jsonify({'result': {'messages': payload}}), 200