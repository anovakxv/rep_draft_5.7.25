# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app import db
from app.models.People_Models.Messaging_Models.GroupChatMetaData import Chats
from app.models.People_Models.Messaging_Models.GroupChatUsers import ChatsUsers
from app.models.People_Models.user import User
from app.models.People_Models.Messaging_Models.Group_Messages import GroupMessage
from app.utils.auth import jwt_required

group_chat_bp = Blueprint('group_chat', __name__)

@group_chat_bp.route('/group_chat', methods=['GET'])  # CHANGED (was /api/group_chat)
@jwt_required
def api_group_chat():
    user_id = g.current_user.id
    chats_id = request.args.get('chats_id')
    limit = int(request.args.get('limit', 50))
    offset = int(request.args.get('offset', 0))

    if not user_id:
        return jsonify({'error': 'Login error!'}), 401
    if not chats_id:
        return jsonify({'error': 'chats_id is empty!'}), 400
    if offset < 0:
        return jsonify({'error': 'offset is wrong!'}), 400
    if limit > 4096:
        return jsonify({'error': 'limit should be <= 4096'}), 400

    chat = Chats.query.filter_by(id=chats_id).first()
    if not chat:
        return jsonify({'error': 'Chat not found!'}), 404

    users = db.session.query(User).join(
        ChatsUsers, ChatsUsers.users_id == User.id
    ).filter(ChatsUsers.chats_id == chats_id).all()
    users_result = [u.as_dict() for u in users]

    messages = GroupMessage.query.filter_by(chat_id=chats_id)\
        .order_by(GroupMessage.created_at.desc())\
        .offset(offset).limit(limit).all()

    flat_messages = []
    for m in reversed(messages):
        sender = m.sender
        full_name = (getattr(sender, "full_name", None) or
                     f"{getattr(sender,'fname','')} {getattr(sender,'lname','')}".strip())
        flat_messages.append({
            "id": m.id,
            "sender_id": m.sender_id,
            "sender_name": full_name or "",
            "sender_photo_url": getattr(sender, "profile_picture_url", None) if sender else None,
            "text": m.text,
            "timestamp": m.created_at.strftime("%Y-%m-%dT%H:%M:%SZ")
        })

    result = {
        'chat': chat.as_dict() if hasattr(chat, 'as_dict') else {},
        'users': users_result,
        'messages': flat_messages
    }
    # --- Mark group chat as read for this user ---
    if flat_messages:
        newest_id = flat_messages[-1]['id']
        cu_row = ChatsUsers.query.filter_by(chats_id=chats_id, users_id=user_id).first()
        if cu_row and (cu_row.last_read_message_id is None or cu_row.last_read_message_id < newest_id):
            cu_row.last_read_message_id = newest_id
            try:
                db.session.commit()
            except Exception as e:
                db.session.rollback()
                print(f"[GroupChat] Could not update last_read_message_id: {e}")
    # --- End mark as read ---
    
    return jsonify({'result': result})