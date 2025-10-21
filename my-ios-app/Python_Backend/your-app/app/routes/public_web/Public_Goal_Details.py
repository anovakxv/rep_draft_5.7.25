# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: October 2025
# PUBLIC WEB ROUTES - Read-only access for unauthenticated users

from flask import Blueprint, request, jsonify
from app import db
from app.models.ValueMetric_Models.Goal import Goal
from app.models.ValueMetric_Models.GoalTeam import GoalTeam
from app.models.ValueMetric_Models.GoalProgressLog import GoalProgressLog
from app.models.People_Models.user import User
from app.models.Purpose_Models.Portal import Portal
from collections import OrderedDict

public_goal_details_bp = Blueprint('public_goal_details', __name__)

def patched_chart_data(goal, increment='day', num_periods=7):
    """
    Helper to generate chart data grouped by time increment.
    """
    logs = goal.progress_logs.order_by(GoalProgressLog.timestamp.asc()).all()
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

    # Only keep the last num_periods periods
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

@public_goal_details_bp.route('/goal/<int:goal_id>', methods=['GET'])
def api_public_goal_details(goal_id):
    """
    PUBLIC API: Returns detailed information for a single goal (no authentication required).
    Used for public web app GoalsDetailView.

    Path params:
    - goal_id: ID of the goal to fetch

    Query params:
    - num_periods: number of time periods for chart data (default: 7)
    """
    if not goal_id:
        return jsonify({'error': 'goal_id required'}), 400

    num_periods = int(request.args.get('num_periods', 7))

    # Fetch goal
    goal = Goal.query.get(goal_id)
    if not goal:
        return jsonify({'error': "Goal not found"}), 404

    # Determine increment from reporting increment title
    increment = 'month'
    if goal.reporting_increment and hasattr(goal.reporting_increment, "title"):
        title = goal.reporting_increment.title.lower().strip()
        if title == "daily" or "day" in title:
            increment = "day"
        elif title == "weekly" or "week" in title:
            increment = "week"
        elif title == "monthly" or "month" in title:
            increment = "month"

    # Generate chart data
    chart_data = patched_chart_data(goal, increment=increment, num_periods=num_periods)

    # Get team members
    team_members = GoalTeam.query.filter_by(goals_id=goal.id, confirmed=1).all()
    team_user_ids = set([goal.users_id] + [tm.users_id2 for tm in team_members])

    # Get all user IDs from progress logs
    logs = GoalProgressLog.query.filter_by(goals_id=goal.id).order_by(
        GoalProgressLog.timestamp.desc()
    ).limit(20).all()
    progress_log_user_ids = set([log.users_id for log in logs if log.users_id])

    # Union team and progress log user IDs
    all_user_ids = team_user_ids.union(progress_log_user_ids)
    users = User.query.filter(User.id.in_(all_user_ids)).all()

    # Serialize team members
    team = [
        {
            "id": u.id,
            "name": f"{getattr(u, 'fname', '')} {getattr(u, 'lname', '')}".strip() or getattr(u, 'username', ''),
            "imageName": getattr(u, 'profile_picture_url', '') or "profile_placeholder"
        }
        for u in users
    ]

    # Serialize progress logs
    a_latest_progress = [log.as_dict() for log in logs]

    # Build result dict
    result = goal.as_dict()

    # Add portal name if exists
    if goal.portals_id:
        portal = Portal.query.get(goal.portals_id)
        result["portalName"] = portal.name if portal else None
    else:
        result["portalName"] = None

    # Calculate filled_quota and progress
    if goal.goal_type == "Recruiting":
        result["filled_quota"] = GoalTeam.query.filter_by(goals_id=goal.id, confirmed=1).count()
    else:
        latest_log = GoalProgressLog.query.filter_by(goals_id=goal.id).order_by(
            GoalProgressLog.timestamp.desc()
        ).first()
        result["filled_quota"] = latest_log.value if latest_log else 0

    # Calculate progress percentage
    if result.get("quota"):
        result["progress"] = round(result["filled_quota"] / result["quota"], 2)
        result["progress_percent"] = round(100 * result["filled_quota"] / result["quota"])
    else:
        result["progress"] = 0
        result["progress_percent"] = 0

    result["valueString"] = str(int(result["filled_quota"]))
    result["team"] = team
    result["aLatestProgress"] = a_latest_progress
    result["chartData"] = chart_data

    return jsonify({'result': result})
