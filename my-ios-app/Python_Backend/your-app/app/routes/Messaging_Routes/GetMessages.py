# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app import db
from app.models.People_Models.Messaging_Models.Direct_Messages import DirectMessage
from app.models.People_Models.Messaging_Models.Group_Messages import GroupMessage
from app.models.People_Models.user import User
from app.models.Purpose_Models.Portal import Portal
from app.models.People_Models.Messaging_Models.GroupChatMetaData import Chats
from app.models.People_Models.Messaging_Models.messages_read import MessagesRead
from app.models.People_Models.Messaging_Models.GroupChatUsers import ChatsUsers
# from app.models.users_hidden_conversations import UsersHiddenConversations
# from app.models.chats_hidden_conversations import ChatsHiddenConversations
from app.utils.auth import jwt_required

user_bp = Blueprint('get_messages', __name__)

@user_bp.route('/get_messages', methods=['GET'])
@jwt_required
def api_get_messages():
    user_id = g.current_user.id
    if not user_id:
        return jsonify({'error': 'Login error!'}), 401

    args = request.args
    # show_hidden = args.get('show_hidden', '1')
    newer_than_id = args.get('newer_than_id')
    chats_id = args.get('chats_id')
    users_id = args.get('users_id')
    order = args.get('order', 'ASC').upper()
    limit = int(args.get('limit', 50))
    offset = int(args.get('offset', 0))
    mark_as_read = args.get('mark_as_read', '0') == '1'

    if order not in ['ASC', 'DESC']:
        return jsonify({'error': 'order is wrong! ASC or DESC required'}), 400
    if offset < 0:
        return jsonify({'error': 'offset is wrong!'}), 400
    if limit > 4096:
        return jsonify({'error': 'limit should be < 4096'}), 400

    # Mark already read messages
    already_read_ids = set(
        r.messages_id for r in MessagesRead.query.filter_by(users_id=user_id).limit(1024).all()
    )

    messages = []
    # Direct messages
    if users_id and not chats_id:
        query = DirectMessage.query.filter(
            ((DirectMessage.sender_id == user_id) & (DirectMessage.recipient_id == users_id)) |
            ((DirectMessage.recipient_id == user_id) & (DirectMessage.sender_id == users_id))
        )
        if newer_than_id:
            query = query.filter(DirectMessage.id > int(newer_than_id))
        query = query.order_by(DirectMessage.created_at.asc() if order == 'ASC' else DirectMessage.created_at.desc())
        messages = query.offset(offset).limit(limit).all()
    # Group messages
    elif chats_id:
        query = GroupMessage.query.filter(GroupMessage.chat_id == chats_id)
        if newer_than_id:
            query = query.filter(GroupMessage.id > int(newer_than_id))
        query = query.order_by(GroupMessage.created_at.asc() if order == 'ASC' else GroupMessage.created_at.desc())
        messages = query.offset(offset).limit(limit).all()
    # Inbox/grouped view
    else:
        direct_query = DirectMessage.query.filter(
            (DirectMessage.sender_id == user_id) | (DirectMessage.recipient_id == user_id)
        )
        group_query = GroupMessage.query.filter(
            GroupMessage.chat_id.in_(
                db.session.query(ChatsUsers.chats_id).filter_by(users_id=user_id)
            )
        )
        if newer_than_id:
            direct_query = direct_query.filter(DirectMessage.id > int(newer_than_id))
            group_query = group_query.filter(GroupMessage.id > int(newer_than_id))
        direct_query = direct_query.order_by(DirectMessage.created_at.asc() if order == 'ASC' else DirectMessage.created_at.desc())
        group_query = group_query.order_by(GroupMessage.created_at.asc() if order == 'ASC' else GroupMessage.created_at.desc())
        direct_messages = direct_query.offset(offset).limit(limit).all()
        group_messages = group_query.offset(offset).limit(limit).all()
        messages = direct_messages + group_messages
        messages.sort(key=lambda m: m.created_at, reverse=(order == 'DESC'))

    # Build message list using as_dict()
    aData = []
    portal_ids = set()
    chat_ids = set()
    for msg in messages:
        msg_dict = msg.as_dict()
        msg_dict['read'] = '1' if msg.id in already_read_ids else '0'
        # Collect related portal/chat ids for context
        if hasattr(msg, 'portal_id') and msg.portal_id:
            portal_ids.add(msg.portal_id)
        if hasattr(msg, 'chat_id') and msg.chat_id:
            chat_ids.add(msg.chat_id)
        aData.append(msg_dict)

    # Mark messages as read if needed
    if mark_as_read and aData:
        unread_ids = [m['id'] for m in aData if m['read'] == '0']
        for mid in unread_ids:
            if not MessagesRead.query.filter_by(users_id=user_id, messages_id=mid).first():
                db.session.add(MessagesRead(users_id=user_id, messages_id=mid))
        db.session.commit()

    # Optionally, preload portals and chats for context
    portals = Portal.query.filter(Portal.id.in_(portal_ids)).all() if portal_ids else []
    chats = Chats.query.filter(Chats.id.in_(chat_ids)).all() if chat_ids else []

    aPortals = [p.as_dict() for p in portals]
    aChats = [c.as_dict() for c in chats]

    result = {
        'messages': aData,
        'portals': aPortals,
        'chats': aChats
    }
    return jsonify(result)
