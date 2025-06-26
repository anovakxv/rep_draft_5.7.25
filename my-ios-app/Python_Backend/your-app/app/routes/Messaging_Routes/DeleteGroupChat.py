
from flask import Blueprint, request, jsonify, session
from app import db
from app.models.chats import Chats
from app.models.chats_users import ChatsUsers

user_bp = Blueprint('user', __name__)

@user_bp.route('/api/user/delete_chat', methods=['POST'])
def api_delete_chat():
    data = request.get_json()
    user_id = session.get('user_id')
    chats_id = data.get('chats_id')

    if not user_id:
        return jsonify({'error': 'login required!'}), 401
    if not chats_id:
        return jsonify({'error': 'chats_id required!'}), 400

    chat = Chats.query.filter_by(id=chats_id).first()
    if not chat:
        return jsonify({'error': 'chat not found'}), 404

    # Check if user is a member of the chat
    is_member = ChatsUsers.query.filter_by(chats_id=chats_id, users_id=user_id).count()
    if not is_member:
        # Check if user is the chat creator
        if chat.users_id != user_id:
            return jsonify({'error': '503'}), 403

    # Delete chat and related data
    db.session.delete(chat)
    ChatsUsers.query.filter_by(chats_id=chats_id).delete()
    db.session.commit()

    return jsonify({'result':
    