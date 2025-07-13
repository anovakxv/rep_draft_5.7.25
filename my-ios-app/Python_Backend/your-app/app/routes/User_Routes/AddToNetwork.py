# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app import db
from app.models.People_Models.user import User
from app.models.People_Models.UserNetwork import UserNetwork
from app.utils.auth import jwt_required

user_bp = Blueprint('add_to_network', __name__)

def does_user_block(blocker_id, blocked_id):
    # Dummy implementation, replace with your actual block logic if needed
    return False

@user_bp.route('/network_action', methods=['POST'])
@jwt_required
def api_add_to_network_action():
    data = request.get_json()
    user_id = g.current_user.id
    target_user_id = data.get('target_user_id')
    todo = data.get('action')

    if not user_id:
        return jsonify({'error': 'Login error!'}), 401
    if not target_user_id:
        return jsonify({'error': 'users_id is empty!'}), 400
    if not todo or todo not in ['add', 'delete']:
        return jsonify({'error': "todo is empty or wrong! Supported: add, delete"}), 400

    # Prevent self-networking
    if str(user_id) == str(target_user_id):
        return jsonify({'error': "You can't add yourself to your own network."}), 400

    # Check if target user exists
    if not User.query.filter_by(id=target_user_id).first():
        return jsonify({'error': "That users_id doesn't exist!"}), 404

    exists = UserNetwork.query.filter_by(users_id1=user_id, users_id2=target_user_id).first()

    if todo == 'add':
        if exists:
            return jsonify({'error': f"User '{target_user_id}' is already in your network"}), 400
        if does_user_block(target_user_id, user_id):
            return jsonify({'error': 'blocked'}), 403
        new_network = UserNetwork(users_id1=user_id, users_id2=target_user_id)
        db.session.add(new_network)
        db.session.commit()
        return jsonify({'result': 'added'})
    elif todo == 'delete':
        if not exists:
            return jsonify({'error': 'Not in your network'}), 404
        db.session.delete(exists)
        db.session.commit()
        return jsonify({'result': 'deleted'})

    return jsonify({'error': 'Unknown error'}), 400
