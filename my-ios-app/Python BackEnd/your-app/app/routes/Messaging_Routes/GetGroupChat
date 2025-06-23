from flask import Blueprint, request, jsonify, session
from app import db
from app.models.chats import Chats
from app.models.chats_users import ChatsUsers
from app.models.user import User
from app.models.People_Models.Messaging_Models.Group_Messages import GroupMessage

group_chat_bp = Blueprint('group_chat', __name__)

@group_chat_bp.route('/api/group_chat', methods=['GET'])
def api_group_chat():
    user_id = session.get('user_id')
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

    # Get chat info
    chat = Chats.query.filter_by(id=chats_id).first()
    if not chat:
        return jsonify({'error': 'Chat not found!'}), 404

    # Get users in the chat
    users = db.session.query(User).join(
        ChatsUsers, ChatsUsers.users_id == User.id
    ).filter(ChatsUsers.chats_id == chats_id).all()
    users_result = [u.as_dict() for u in users]

    # Get group messages in the chat (latest first, then reverse for chronological)
    messages = GroupMessage.query.filter_by(chat_id=chats_id)\
        .order_by(GroupMessage.created_at.desc())\
        .offset(offset).limit(limit).all()

    # Use as_dict() for unified message response (includes sender object)
    messages_result = [msg.as_dict() for msg in reversed(messages)]

    return jsonify({
        'result': {
            'chat': chat.as_dict() if hasattr(chat, 'as_dict') else {},
            'users': users_result,
            'messages':
            