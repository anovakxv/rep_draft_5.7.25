
from flask import Blueprint, request, jsonify, session
from app import db
from app.models.message import Message

user_bp = Blueprint('user', __name__)

@user_bp.route('/api/user/delete_message', methods=['POST'])
def api_delete_message():
    data = request.get_json()
    user_id = session.get('user_id')
    messages_id = data.get('messages_id')
    users_id = data.get('users_id')

    if not user_id:
        return jsonify({'error': 'Login error!'}), 401
    if not messages_id and not users_id:
        return jsonify({'error': 'messages_id AND users_id are empty!'}), 400
    if messages_id and users_id:
        return jsonify({'error': 'messages_id OR users_id required, not both!'}), 400

    aLog = []

    if messages_id:
        # Delete a single message if the user is a participant
        msg = Message.query.filter(
            Message.id == messages_id,
            ((Message.users_id1 == user_id) | (Message.users_id2 == user_id))
        ).first()
        if msg:
            db.session.delete(msg)
            db.session.commit()
            aLog.append(f"{msg.id}; S3: ")
    elif users_id:
        # Delete all messages between the two users
        msgs = Message.query.filter(
            ((Message.users_id1 == user_id) & (Message.users_id2 == users_id)) |
            ((Message.users_id2 == user_id) & (Message.users_id1 == users_id))
        ).all()
        for msg in msgs:
            db.session.delete(msg)
            aLog.append(f"{msg.id}; S3: ")
        db.session.commit()

    return
    