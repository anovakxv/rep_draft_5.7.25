# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app import db
from app.models.Purpose_Models.Portal import Portal
from app.models.People_Models.user import User
from app.models.ValueMetric_Models.Goal import Goal
from app.utils.auth import jwt_required

# Replace the message sending and goal progress logic with your actual implementations.
# This route expects a JSON body with user_id, portals_id, and aUsersIDs (list of user IDs to share with).

portal_bp = Blueprint('portal_share', __name__)

@portal_bp.route('/share/message', methods=['POST'])
@jwt_required
def api_portal_share_via_message():
    data = request.get_json()
    user_id = g.current_user.id or data.get('user_id')
    portal_id = data.get('portals_id')
    users_ids = data.get('aUsersIDs')

    if not user_id:
        return jsonify({'error': 'Login error!'}), 401
    if not portal_id:
        return jsonify({'error': 'portals_id required!'}), 400
    if not isinstance(users_ids, list) or not users_ids:
        return jsonify({'error': 'aUsersIDs required!'}), 400

    # Check portal exists
    portal = Portal.query.filter_by(id=portal_id).first()
    if not portal:
        return jsonify({'error': "the portal doesn't exist!"}), 404

    # Validate users exist
    valid_users = User.query.filter(User.id.in_(users_ids)).all()
    valid_user_ids = {str(u.id) for u in valid_users}
    log = {}

    for uid in users_ids:
        if str(uid) not in valid_user_ids:
            log[uid] = {'error': 'User does not exist'}
            continue

        # Here you would send a message (implement your own messaging logic)
        # For now, just log the action
        log[uid] = {'message': 'I share a portal with you', 'portals_id': portal_id}

        # For each goal of type 2 (marketing) on this portal, log goal progress
        goals = Goal.query.filter_by(portals_id=portal_id, goal_types_id=2).all()
        for goal in goals:
            # Implement your log_goal_progress logic here
            # log_goal_progress(user_id, {'goals_id': goal.id, 'added_value': 1}, "marketing")
            pass  # Replace with your actual logic

    return jsonify({'result': log})
