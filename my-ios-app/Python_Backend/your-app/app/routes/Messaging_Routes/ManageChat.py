# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app import db
from app.models.People_Models.Messaging_Models.GroupChatMetaData import Chats
from app.models.People_Models.Messaging_Models.GroupChatUsers import ChatsUsers
from app.models.People_Models.user import User
from app.utils.auth import jwt_required

user_bp = Blueprint('manage_chat', __name__)

@user_bp.route('/manage_chat', methods=['POST'])
@jwt_required
def api_manage_chat():
    data = request.get_json()
    user_id = g.current_user.id
    chats_id = data.get('chats_id')
    title = data.get('title')
    aAddIDs = data.get('aAddIDs', [])
    aDelIDs = data.get('aDelIDs', [])

    if not user_id:
        return jsonify({'error': 'login required!'}), 401

    if aDelIDs and not chats_id:
        return jsonify({'error': 'for aDelIDs chats_id required!'}), 400

    # Validate chat membership if editing existing chat
    chat = None
    if chats_id:
        chat = Chats.query.filter_by(id=chats_id).first()
        if not chat:
            return jsonify({'error': 'chat not found'}), 404
        is_member = ChatsUsers.query.filter_by(chats_id=chats_id, users_id=user_id).count()
        if not is_member:
            return jsonify({'error': 'You are not a member of this chat.'}), 403

    # Validate users to add/delete (only add valid users)
    aAddIDsToDb = [uid for uid in aAddIDs if User.query.filter_by(id=uid).first()]
    aDelIDsToDb = [uid for uid in aDelIDs if User.query.filter_by(id=uid).first()]

    # Create new chat if chats_id is not provided
    if not chats_id:
        chat = Chats(name=title or "Untitled Chat", created_by=user_id)
        db.session.add(chat)
        db.session.commit()
        chats_id = chat.id
        if title is not None:  # Ensure title is set even on creation
            chat.name = title
            db.session.commit()
        db.session.add(ChatsUsers(users_id=user_id, chats_id=chats_id))
        db.session.commit()

        # --- Ensure chat appears in lists even before first message ---
        try:
            from app.models.People_Models.Messaging_Models.Group_Messages import GroupMessage
            from datetime import datetime

            # Create a system message (empty text) so chat appears in lists
            system_msg = GroupMessage(
                chat_id=chats_id,
                sender_id=user_id,
                text="",
                created_at=datetime.utcnow(),
                is_system=True  # If your model supports this flag
            )
            db.session.add(system_msg)
            db.session.commit()
        except Exception as e:
            print(f"[GroupChat] Non-critical: Could not create system message: {e}")
    else:
        if title is not None:
            chat.name = title
            db.session.commit()

    # Get current chat users
    current_users = {cu.users_id for cu in ChatsUsers.query.filter_by(chats_id=chats_id).all()}

    # Add users to chat
    aAddIDsToDbLog = {}
    for uid in aAddIDsToDb:
        if uid in current_users:
            aAddIDsToDbLog[uid] = 'already in the chat'
        else:
            db.session.add(ChatsUsers(users_id=uid, chats_id=chats_id))
            aAddIDsToDbLog[uid] = 'ok'
    db.session.commit()

    # Remove users from chat
    aDelIDsToDbLog = {}
    for uid in aDelIDsToDb:
        if uid not in current_users:
            aDelIDsToDbLog[uid] = 'not in the chat'
        else:
            ChatsUsers.query.filter_by(users_id=uid, chats_id=chats_id).delete()
            aDelIDsToDbLog[uid] = 'ok'
    db.session.commit()

    # Optionally, return updated chat and user list for frontend
    updated_chat = Chats.query.filter_by(id=chats_id).first()
    chat_dict = updated_chat.as_dict() if updated_chat and hasattr(updated_chat, 'as_dict') else {}
    chat_users = ChatsUsers.query.filter_by(chats_id=chats_id).all()
    user_ids = [cu.users_id for cu in chat_users]
    users = User.query.filter(User.id.in_(user_ids)).all()
    users_result = [u.as_dict() for u in users]

    result = {
        'chats_id': chats_id,
        'aAddIDsToDbLog': aAddIDsToDbLog,
        'aDelIDsToDbLog': aDelIDsToDbLog,
        'chat': chat_dict,
        'users': users_result
    }
    return jsonify(result)

@user_bp.route('/delete_chat', methods=['POST'])
@jwt_required
def api_delete_group_chat():
    data = request.get_json()
    user_id = g.current_user.id
    chats_id = data.get('chats_id')

    if not user_id:
        return jsonify({'error': 'Login error!'}), 401
    if not chats_id:
        return jsonify({'error': 'chats_id is empty!'}), 400

    chat = Chats.query.filter_by(id=chats_id).first()
    if not chat:
        return jsonify({'error': "Chat not found"}), 404

    if chat.created_by != user_id:
        return jsonify({'error': "Only the creator can delete this group chat."}), 403

    # Single delete; DB cascades remove group_messages & chats_users rows
    db.session.delete(chat)
    db.session.commit()

    return jsonify({'result': f"Group chat '{chats_id}' deleted."})
