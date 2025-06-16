
from flask import Blueprint, request, jsonify, session
from app import db
from app.models.user import User
from app.models.users_blocked import UsersBlocked

user_bp = Blueprint('user', __name__)

@user_bp.route('/api/user/block_user', methods=['POST'])
def api_block_user():
    data = request.get_json()
    user_id = session.get('user_id')
    target_user_id = data.get('users_id')
    todo = data.get('todo')

    if not user_id:
        return jsonify({'error': 'login required!'}), 401
    if not target_user_id:
        return jsonify({'error': 'users_id is empty!'}), 400
    if not todo or todo not in ['block', 'unblock']:
        return jsonify({'error': "todo is empty or wrong! Supported: block, unblock"}), 400

    # Check if target user exists
    if not User.query.filter_by(id=target_user_id).first():
        return jsonify({'error': "that users_id doesn't exist!"}), 404

    exists = UsersBlocked.query.filter_by(users_id1=user_id, users_id2=target_user_id).first()

    if todo == 'block':
        if exists:
            return jsonify({'error': f"You are already blocking '{target_user_id}'"}), 400
        blocked = UsersBlocked(users_id1=user_id, users_id2=target_user_id)
        db.session.add(blocked)
        db.session.commit()
    elif todo == 'unblock':
        if not exists:
            return jsonify({'error': f"You are not blocking '{target_user_id}'"}), 400
        db.session.delete(exists)
        