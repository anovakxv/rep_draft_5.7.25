# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app import db
from app.models.People_Models.user import User
# from app.models.users_hidden_conversations import UsersHiddenConversations
from app.utils.auth import jwt_required

user_bp = Blueprint('hide_convo', __name__)

@user_bp.route('/hide_conversation', methods=['POST'])
@jwt_required
def api_hide_conversation():
    data = request.get_json()
    user_id = g.current_user.id
    other_user_id = data.get('users_id')
    todo = data.get('todo')

    if not user_id:
        return jsonify({'error': 'Login error!'}), 401
    if not other_user_id:
        return jsonify({'error': 'users_id is empty!'}), 400
    if not todo or todo not in ['hide', 'show']:
        return jsonify({'error': "todo is empty or wrong! Supported: hide, show"}), 400

    # Check if the other user exists
    if not User.query.filter_by(id=other_user_id).first():
        return jsonify({'error': "that users_id doesn't exist!"}), 404

    exists = UsersHiddenConversations.query.filter_by(users_id1=user_id, users_id2=other_user_id).first()

    if todo == 'hide':
        if exists:
            return jsonify({'error': f"You are already hiding '{other_user_id}'"}), 400
        hidden = UsersHiddenConversations(users_id1=user_id, users_id2=other_user_id)
        db.session.add(hidden)
        db.session.commit()
        return jsonify({'result': f"Conversation with '{other_user_id}' hidden."})
    elif todo == 'show':
        if not exists:
            return jsonify({'error': f"You are not hiding '{other_user_id}'"}), 400
        db.session.delete(exists)
        db.session.commit()
        return jsonify({'result': f"Conversation with '{other_user_id}' shown."})
    