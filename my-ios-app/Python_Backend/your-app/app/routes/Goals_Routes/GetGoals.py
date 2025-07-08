# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app.models.ValueMetric_Models.Goal import Goal
from app.utils.auth import jwt_required

goals_bp = Blueprint('get_user_goals', __name__)

# GET /api/goals/list?users_id=1
@goals_bp.route('/list', methods=['GET'])
@jwt_required
def get_goals_by_user():
    users_id = request.args.get('users_id', type=int)
    if not users_id:
        return jsonify({"error": "users_id required"}), 400

    goals = Goal.query.filter_by(users_id=users_id).all()

    aGoals = [goal.as_dict() for goal in goals]

    return jsonify({"aGoals": aGoals})

# GET /api/goals/portal?portals_id=1
@goals_bp.route('/portal', methods=['GET'])
@jwt_required
def get_goals_by_portal():
    portals_id = request.args.get('portals_id', type=int)
    if not portals_id:
        return jsonify({"error": "portals_id required"}), 400

    goals = Goal.query.filter_by(portals_id=portals_id).all()

    aGoals = [goal.as_dict() for goal in goals]

    return jsonify({"aGoals": aGoals})