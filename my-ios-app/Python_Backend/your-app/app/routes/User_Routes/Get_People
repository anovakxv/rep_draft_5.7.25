from flask import Blueprint, request, jsonify, session
from app import db
from app.models.People_Models.Messaging_Models.Direct_Messages import DirectMessage
from app.models.People_Models.Messaging_Models.Group_Messages import GroupMessage
from app.models.user import User
from app.models.chats import Chats
from app.models.chats_users import ChatsUsers
from app.models.users_network import UserNetwork

people_bp = Blueprint('people', __name__)

@people_bp.route('/api/active_chat_list', methods=['GET'])
def api_active_chat_list():
    """
    Returns the user's active chat list (OPEN tab): all direct and group chats the user is part of,
    sorted by most recent message (direct or group) descending.
    """
    user_id = session.get('user_id') or request.args.get('user_id')
    limit = int(request.args.get('limit', 50))
    offset = int(request.args.get('offset', 0))

    if not user_id:
        return jsonify({'error': 'Login error!'}), 401
    if limit > 4096:
        return jsonify({'error': 'limit should be <= 4096'}), 400
    if offset < 0:
        return jsonify({'error': 'offset is wrong!'}), 400

    # Get the latest message per direct chat (between user and each contact)
    direct_contacts = db.session.query(
        db.case(
            [(DirectMessage.sender_id == user_id, DirectMessage.recipient_id)],
            else_=DirectMessage.sender_id
        ).label('contact_id'),
        db.func.max(DirectMessage.created_at).label('last_message_time')
    ).filter(
        (DirectMessage.sender_id == user_id) | (DirectMessage.recipient_id == user_id)
    ).group_by('contact_id').subquery()

    # Get the latest message per group chat
    group_chats = db.session.query(
        GroupMessage.chat_id,
        db.func.max(GroupMessage.created_at).label('last_message_time')
    ).filter(
        GroupMessage.chat_id.in_(
            db.session.query(ChatsUsers.chats_id).filter_by(users_id=user_id)
        )
    ).group_by(GroupMessage.chat_id).subquery()

    # Collect all latest chat events (direct and group), sort by time
    chat_events = []
    # Direct chats
    for row in db.session.query(direct_contacts):
        chat_events.append({
            'type': 'direct',
            'contact_id': row.contact_id,
            'last_message_time': row.last_message_time
        })
    # Group chats
    for row in db.session.query(group_chats):
        chat_events.append({
            'type': 'group',
            'chat_id': row.chat_id,
            'last_message_time': row.last_message_time
        })

    # Sort all chats by last_message_time descending
    chat_events.sort(key=lambda x: x['last_message_time'], reverse=True)
    chat_events = chat_events[offset:offset+limit]

    # Build response: for each chat, include user/chat info and last message
    result = []
    for event in chat_events:
        if event['type'] == 'direct':
            user = User.query.filter_by(id=event['contact_id']).first()
            last_msg = DirectMessage.query.filter(
                ((DirectMessage.sender_id == user_id) & (DirectMessage.recipient_id == event['contact_id'])) |
                ((DirectMessage.recipient_id == user_id) & (DirectMessage.sender_id == event['contact_id']))
            ).order_by(DirectMessage.created_at.desc()).first()
            result.append({
                'type': 'direct',
                'user': user.as_dict() if user else {},
                'last_message': last_msg.as_dict() if last_msg else {},
                'last_message_time': event['last_message_time']
            })
        elif event['type'] == 'group':
            chat = Chats.query.filter_by(id=event['chat_id']).first()
            last_msg = GroupMessage.query.filter_by(chat_id=event['chat_id']).order_by(GroupMessage.created_at.desc()).first()
            result.append({
                'type': 'group',
                'chat': chat.as_dict() if chat else {},
                'last_message': last_msg.as_dict() if last_msg else {},
                'last_message_time': event['last_message_time']
            })

    return jsonify({'result': result})

@people_bp.route('/api/filter_people', methods=['GET'])
def filter_people():
    """
    Returns a list of people for the MainScreen, filtered by tab: open, ntwk, all.
    Use ?user_id=...&tab=open|ntwk|all
    """
    user_id = session.get('user_id') or request.args.get('user_id')
    tab = request.args.get('tab', 'open')  # 'open', 'ntwk', 'all'
    keyword = request.args.get('keyword', '')
    limit = int(request.args.get('limit', 50))
    offset = int(request.args.get('offset', 0))

    if not user_id:
        return jsonify({'error': 'Login error!'}), 401
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
    result = [u.as_dict() for u in users]
    return jsonify({'result': result})
