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
    # Robustly determine increment from reporting increment title
    increment = "month"
    if hasattr(goal, "reporting_increment") and goal.reporting_increment and hasattr(goal.reporting_increment, "title"):
        reporting_increment_title = goal.reporting_increment.title
        title = reporting_increment_title.lower().strip()
        print(f"[DEBUG] Normalized reporting_increment.title: '{title}'")
        if title == "daily":
            increment = "day"
        elif title == "weekly":
            increment = "week"
        elif title == "monthly":
            increment = "month"
        elif "day" in title:
            increment = "day"
        elif "week" in title:
            increment = "week"
        elif "month" in title:
            increment = "month"
        else:
            print(f"[DEBUG] Unknown increment title: '{title}', defaulting to 'month'")
    print(f"[DEBUG] Chart increment selected: {increment}")
    return increment

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
        result = goal.as_dict(increment=increment, num_periods=4)
        aGoals.append(result)

    return jsonify({"aGoals": aGoals})

# GET /api/goals/portal?portals_id=1
@goals_bp.route('/portal', methods=['GET'])
@jwt_required
def get_goals_by_portal():
    portals_id = request.args.get('portals_id', type=int)
    if not portals_id:
        return jsonify({"error": "portals_id required"}), 400

    # Eager-load reporting_increment so get_increment works!
    goals = (
        Goal.query.options(joinedload(Goal.reporting_increment))
        .filter_by(portals_id=portals_id)
        .all()
    )

    aGoals = []
    for goal in goals:
        increment = get_increment(goal)
        result = goal.as_dict(increment=increment, num_periods=4)
        aGoals.append(result)

    return jsonify({"aGoals": aGoals})