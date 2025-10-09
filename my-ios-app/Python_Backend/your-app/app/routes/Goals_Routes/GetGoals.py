# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app.models.ValueMetric_Models.Goal import Goal
from app.models.ValueMetric_Models.GoalTeam import GoalTeam
from app.models.ValueMetric_Models.GoalProgressLog import GoalProgressLog
from app.utils.auth import jwt_required
from app import db
from sqlalchemy.orm import joinedload

goals_bp = Blueprint('get_user_goals', __name__)

def get_increment(goal):
    # Robustly determine increment from reporting increment title
    increment = "month"
    if hasattr(goal, "reporting_increment") and goal.reporting_increment and hasattr(goal.reporting_increment, "title"):
        reporting_increment_title = goal.reporting_increment.title
        title = reporting_increment_title.lower().strip()
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

    goals = (
        Goal.query.options(joinedload(Goal.reporting_increment))
        .filter_by(portals_id=portals_id)
        .all()
    )

    aGoals = []
    for goal in goals:
        # --- PATCH: Determine increment from reporting increment title ---
        increment = 'month'
        if goal.reporting_increment and hasattr(goal.reporting_increment, "title"):
            title = goal.reporting_increment.title.lower().strip()
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

        # --- PATCH: Chart Data Grouping ---
        def patched_chart_data(self, increment='day', num_periods=4):
            from collections import OrderedDict
            logs = self.progress_logs.order_by(GoalProgressLog.timestamp.asc()).all()
            cumulative = 0
            data = OrderedDict()
            for log in logs:
                if log.timestamp:
                    if increment == 'month':
                        label = log.timestamp.strftime('%Y-%m')
                        display_label = log.timestamp.strftime('%b')
                    elif increment == 'week':
                        label = f"{log.timestamp.year}-W{log.timestamp.isocalendar()[1]}"
                        display_label = f"W{log.timestamp.isocalendar()[1]}"
                    elif increment == 'day':
                        label = log.timestamp.strftime('%Y-%m-%d')
                        display_label = log.timestamp.strftime('%d %b')
                    else:
                        label = log.timestamp.strftime('%Y-%m')
                        display_label = log.timestamp.strftime('%b')
                    cumulative += float(log.added_value or 0)
                    data[label] = (cumulative, display_label)
            items = list(data.items())[-num_periods:]
            chart_data = [
                {
                    "id": idx + 1,
                    "value": value,
                    "valueLabel": str(value),
                    "bottomLabel": display_label
                }
                for idx, (label, (value, display_label)) in enumerate(items)
            ]
            return chart_data
        goal.chart_data = patched_chart_data.__get__(goal, Goal)
        chart_data = goal.chart_data(increment=increment, num_periods=4)

        result = goal.as_dict(increment=increment, num_periods=4)
        result["chartData"] = chart_data
        aGoals.append(result)

    return jsonify({"aGoals": aGoals})