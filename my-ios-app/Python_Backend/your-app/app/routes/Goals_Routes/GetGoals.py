# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app.models.ValueMetric_Models.Goal import Goal
from app.models.ValueMetric_Models.GoalTeam import GoalTeam
from app.utils.auth import jwt_required
from app import db

goals_bp = Blueprint('get_user_goals', __name__)

def get_increment(goal):
    # Use the goal's reporting increment title if available
    if hasattr(goal, "reporting_increment") and goal.reporting_increment and hasattr(goal.reporting_increment, "title"):
        title = goal.reporting_increment.title.lower()
        if "day" in title:
            return "day"
        elif "week" in title:
            return "week"
        elif "month" in title:
            return "month"
    return "month"  # Default fallback

# GET /api/goals/list?users_id=1
@goals_bp.route('/list', methods=['GET'])
@jwt_required
def get_goals_by_user():
    users_id = request.args.get('users_id', type=int)
    if not users_id:
        return jsonify({"error": "users_id required"}), 400

    # Return goals where user is creator OR confirmed team member
    goals = (
        db.session.query(Goal)
        .outerjoin(GoalTeam, Goal.id == GoalTeam.goals_id)
        .filter(
            (Goal.users_id == users_id) |
            ((GoalTeam.users_id2 == users_id) & (GoalTeam.confirmed == 1))
        )
        .distinct()
        .all()
    )

    # Use correct increment for chartData, always return 4 bars for GoalListItem
    aGoals = []
    for goal in goals:
        increment = get_increment(goal)
        aGoals.append(goal.as_dict(increment=increment, num_periods=4))

    return jsonify({"aGoals": aGoals})

# GET /api/goals/portal?portals_id=1
@goals_bp.route('/portal', methods=['GET'])
@jwt_required
def get_goals_by_portal():
    portals_id = request.args.get('portals_id', type=int)
    if not portals_id:
        return jsonify({"error": "portals_id required"}), 400

    goals = Goal.query.filter_by(portals_id=portals_id).all()

    # Use correct increment for chartData, always return 4 bars for GoalListItem
    aGoals = []
    for goal in goals:
        increment = get_increment(goal)
        aGoals.append(goal.as_dict(increment=increment, num_periods=4))

    return jsonify({"aGoals": aGoals})