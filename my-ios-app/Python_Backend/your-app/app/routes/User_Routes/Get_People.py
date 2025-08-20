# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app import db
from app.models.People_Models.Messaging_Models.Direct_Messages import DirectMessage
from app.models.People_Models.Messaging_Models.messages_read import MessagesRead
from app.models.People_Models.Messaging_Models.Group_Messages import GroupMessage
from app.models.People_Models.Messaging_Models.GroupChatMetaData import Chats
from app.models.People_Models.Messaging_Models.GroupChatUsers import ChatsUsers
from app.models.People_Models.user import User
from app.models.People_Models.UserNetwork import UserNetwork
from app.models.People_Models.Skill import Skill
from app.models.People_Models.UserSkill import UserSkill
from app.utils.auth import jwt_required

# --- S3 BASE URL ---
S3_BASE_URL = "https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/"

people_bp = Blueprint('people', __name__)

def patch_profile_picture_url(user_row):
    url = user_row.get('profile_picture_url')
    if url and not url.startswith("http"):
        user_row['profile_picture_url'] = S3_BASE_URL + url
    if not url or str(url).strip() == "":
        user_row['profile_picture_url'] = None
    return user_row

def batch_get_users(user_ids):
    users = User.query.filter(User.id.in_(user_ids)).all()
    return {u.id: u for u in users}

# def batch_get_chats(chat_ids):
#     chats = Chats.query.filter(Chats.id.in_(chat_ids)).all()
#     return {c.id: c for c in chats}

def batch_get_last_direct_messages(user_id, contact_ids):
    # Get the latest direct message for each contact
    last_msgs = (
        db.session.query(
            db.case(
                (DirectMessage.sender_id == user_id, DirectMessage.recipient_id),
                else_=DirectMessage.sender_id
            ).label('contact_id'),
            db.func.max(DirectMessage.created_at).label('last_message_time')
        )
        .filter(
            (DirectMessage.sender_id == user_id) | (DirectMessage.recipient_id == user_id),
            db.or_(
                DirectMessage.sender_id.in_([user_id] + contact_ids),
                DirectMessage.recipient_id.in_([user_id] + contact_ids)
            )
        )
        .group_by('contact_id')
        .all()
    )
    # Now fetch the actual last message for each contact
    last_msg_map = {}
    for row in last_msgs:
        last_msg = DirectMessage.query.filter(
            ((DirectMessage.sender_id == user_id) & (DirectMessage.recipient_id == row.contact_id)) |
            ((DirectMessage.recipient_id == user_id) & (DirectMessage.sender_id == row.contact_id))
        ).order_by(DirectMessage.created_at.desc()).first()
        if last_msg:
            last_msg_map[row.contact_id] = last_msg
    return last_msg_map

# def batch_get_last_group_messages(chat_ids):
#     # Get the latest group message for each chat
#     last_msgs = (
#         db.session.query(
#             GroupMessage.chat_id,
#             db.func.max(GroupMessage.created_at).label('last_message_time')
#         )
#         .filter(GroupMessage.chat_id.in_(chat_ids))
#         .group_by(GroupMessage.chat_id)
#         .all()
#     )
#     last_msg_map = {}
#     for row in last_msgs:
#         last_msg = GroupMessage.query.filter_by(chat_id=row.chat_id).order_by(GroupMessage.created_at.desc()).first()
#         if last_msg:
#             last_msg_map[row.chat_id] = last_msg
#     return last_msg_map

@people_bp.route('/api/active_chat_list', methods=['GET'])
@jwt_required
def api_active_chat_list():
    """
    Returns the user's active chat list (OPEN tab): all direct chats and group chats (with at least one message)
    the user is part of, sorted by most recent message descending.
    """
    user_id = g.current_user.id

    limit = int(request.args.get('limit', 50))
    offset = int(request.args.get('offset', 0))

    if limit > 4096:
        return jsonify({'error': 'limit should be <= 4096'}), 400
    if offset < 0:
        return jsonify({'error': 'offset is wrong!'}), 400

    # --- DIRECT CHATS ---
    direct_contacts = db.session.query(
        db.case(
            (DirectMessage.sender_id == user_id, DirectMessage.recipient_id),
            else_=DirectMessage.sender_id
        ).label('contact_id'),
        db.func.max(DirectMessage.created_at).label('last_message_time')
    ).filter(
        (DirectMessage.sender_id == user_id) | (DirectMessage.recipient_id == user_id)
    ).group_by('contact_id').all()

    contact_ids = [row.contact_id for row in direct_contacts]
    users_map = batch_get_users(contact_ids) if contact_ids else {}
    last_direct_msgs = batch_get_last_direct_messages(user_id, contact_ids) if contact_ids else {}

    # --- GROUP CHATS (with at least one message) ---
    group_chats = (
        db.session.query(
            GroupMessage.chat_id,
            db.func.max(GroupMessage.created_at).label('last_message_time')
        )
        .join(ChatsUsers, ChatsUsers.chats_id == GroupMessage.chat_id)
        .filter(ChatsUsers.users_id == user_id)
        .group_by(GroupMessage.chat_id)
        .all()
    )
    chat_ids = [row.chat_id for row in group_chats]
    chats_map = {c.id: c for c in Chats.query.filter(Chats.id.in_(chat_ids)).all()} if chat_ids else {}
    last_group_msgs = {}
    for row in group_chats:
        last_msg = GroupMessage.query.filter_by(chat_id=row.chat_id).order_by(GroupMessage.created_at.desc()).first()
        if last_msg:
            last_group_msgs[row.chat_id] = last_msg

    # --- Get all read message IDs for this user ---
    read_ids = set(r.messages_id for r in MessagesRead.query.filter_by(users_id=user_id).all())

    # --- Collect all latest chat events (direct + group) ---
    chat_events = []
    for row in direct_contacts:
        chat_events.append({
            'type': 'direct',
            'contact_id': row.contact_id,
            'last_message_time': row.last_message_time
        })
    for row in group_chats:
        chat_events.append({
            'type': 'group',
            'chat_id': row.chat_id,
            'last_message_time': row.last_message_time
        })

    # --- Sort all chats by last_message_time descending ---
    chat_events.sort(key=lambda x: x['last_message_time'], reverse=True)
    chat_events = chat_events[offset:offset+limit]

    # --- Build response ---
    # --- Get last_read_message_id for all group chats for this user ---
    last_read_map = {
        c.chats_id: c.last_read_message_id
        for c in ChatsUsers.query.filter_by(users_id=user_id).all()
        if c.last_read_message_id is not None
    }

    result = []
    for event in chat_events:
        if event['type'] == 'direct':
            user = users_map.get(event['contact_id'])
            last_msg = last_direct_msgs.get(event['contact_id'])
            user_dict = user.as_dict() if user else {}
            user_dict = patch_profile_picture_url(user_dict)
            is_read = "1" if last_msg and last_msg.id in read_ids else "0"

            # Ensure last_message_time is ISO8601 string
            last_message_time_str = None
            if event['last_message_time']:
                last_message_time_str = event['last_message_time'].strftime("%Y-%m-%dT%H:%M:%SZ")

            last_message_payload = {}
            if last_msg:
                # Use model helper then inject/override fields we need
                last_message_payload = last_msg.as_dict(read=is_read)
                # Add created_at alias expected by iOS (keep timestamp for backward compatibility)
                last_message_payload['created_at'] = last_message_payload.get('timestamp')

            result.append({
                'id': f"direct-{user.id}" if user else None,
                'type': 'direct',
                'user': user_dict,
                'last_message': last_message_payload,
                'last_message_time': last_message_time_str
            })

        elif event['type'] == 'group':
            chat = chats_map.get(event['chat_id'])
            last_msg = last_group_msgs.get(event['chat_id'])

            last_message_time_str = None
            if event['last_message_time']:
                last_message_time_str = event['last_message_time'].strftime("%Y-%m-%dT%H:%M:%SZ")

            last_message_payload = {}
            if last_msg:
                lm = last_msg.as_dict()
                # Mirror created_at for parity if GroupMessage.as_dict uses 'timestamp'
                if 'timestamp' in lm and 'created_at' not in lm:
                    lm['created_at'] = lm.get('timestamp')
                # --- Add read flag for group chat ---
                last_read_id = last_read_map.get(event['chat_id'])
                if last_read_id is not None and last_msg.id <= last_read_id:
                    lm['read'] = "1"
                else:
                    lm['read'] = "0"
                last_message_payload = lm

            result.append({
                'id': f"group-{chat.id}" if chat else None,
                'type': 'group',
                'chat': chat.as_dict() if chat else {},
                'last_message': last_message_payload,
                'last_message_time': last_message_time_str
            })

    return jsonify({'result': result})

@people_bp.route('/api/filter_people', methods=['GET'])
@jwt_required
def filter_people():
    """
    Returns a list of people for the MainScreen, filtered by tab: open, ntwk, all.
    Use ?tab=open|ntwk|all&keyword=...&limit=...&offset=...
    """
    user_id = g.current_user.id

    tab = request.args.get('tab', 'open')  # 'open', 'ntwk', 'all'
    keyword = request.args.get('keyword', '')
    limit = int(request.args.get('limit', 50))
    offset = int(request.args.get('offset', 0))

    if limit > 4096:
        return jsonify({'error': 'limit should be <= 4096'}), 400
    if offset < 0:
        return jsonify({'error': 'offset is wrong!'}), 400

    query = User.query

    if tab == "open":
        # note: OPEN tab should use /api/active_chat_list, not this endpoint
        return jsonify({'error': 'Use /api/active_chat_list for the OPEN tab.'}), 400
    elif tab == "ntwk":
        # note: NTWK tab = users who are in my network (UserNetwork)
        network_user_ids = db.session.query(UserNetwork.users_id2).filter_by(users_id1=user_id)
        query = query.filter(User.id.in_(network_user_ids))
    elif tab == "all":
        # note: ALL tab = all users except myself
        query = query.filter(User.id != user_id)
    else:
        return jsonify({'error': 'Invalid tab value!'}), 400

    if keyword:
        query = query.filter(
            (User.fname.ilike(f"%{keyword}%")) | (User.lname.ilike(f"%{keyword}%")) | (User.username.ilike(f"%{keyword}%"))
        )

    users = query.offset(offset).limit(limit).all()
    result = []
    for u in users:
        user_dict = u.as_dict()
        user_dict = patch_profile_picture_url(user_dict)
        result.append(user_dict)
    return jsonify({'result': result})