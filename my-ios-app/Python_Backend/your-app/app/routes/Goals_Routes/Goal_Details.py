# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app import db
from app.models.ValueMetric_Models.Goal import Goal
from app.models.ValueMetric_Models.GoalTeam import GoalTeam
from app.models.ValueMetric_Models.GoalProgressLog import GoalProgressLog
from app.models.ValueMetric_Models.ReportingIncrement import ReportingIncrement
from app.models.People_Models.user import User
from app.models.Purpose_Models.Portal import Portal
from app.utils.auth import jwt_required
import logging

goals_bp = Blueprint('goal_details', __name__)

GOAL_TYPE_METRIC_MAP = {
    "Recruiting": "Team Members",
    "Sales": "Dollars",
    "Fund": "Dollars",
    "Marketing": "Shares",
    "Hours": "Hours"
    # "Other" handled separately
}

def check_permission(goal, user_id):
    return user_id == goal.users_id or user_id == goal.lead_id

@goals_bp.route('/details', methods=['GET'])
@jwt_required
def api_goal_details():
    goal_id = request.args.get('goals_id', type=int)
    user_id = g.current_user.id
    if not goal_id:
        return jsonify({'error': 'goals_id required!'}), 400
    goal = Goal.query.get(goal_id)
    if not goal:
        return jsonify({'error': "the goal doesn't exist"}), 404

    # --- PATCH: Determine increment from reporting increment title ---
    increment = 'month'
    reporting_increment_title = None
    if goal.reporting_increment and hasattr(goal.reporting_increment, "title"):
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
        else:
            pass

    # --- PATCH: Chart Data Grouping ---
    def patched_chart_data(self, increment='day', num_periods=7):
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
    goal.chart_data = patched_chart_data.__get__(goal, Goal)
    chart_data = goal.chart_data(increment=increment, num_periods=7)

    # PATCH: Include all users who appear in progress logs, not just team members
    team_members = GoalTeam.query.filter_by(goals_id=goal.id, confirmed=1).all()
    team_user_ids = set([goal.users_id] + [tm.users_id2 for tm in team_members])

    # Get all user IDs from progress logs
    logs = GoalProgressLog.query.filter_by(goals_id=goal.id).order_by(GoalProgressLog.timestamp.desc()).limit(20).all()
    progress_log_user_ids = set([log.users_id for log in logs if log.users_id])

    # Union team and progress log user IDs
    all_user_ids = team_user_ids.union(progress_log_user_ids)
    users = User.query.filter(User.id.in_(all_user_ids)).all()

    team = [
        {
            "id": u.id,
            "name": f"{getattr(u, 'fname', '')} {getattr(u, 'lname', '')}".strip() or getattr(u, 'username', ''),
            "imageName": getattr(u, 'profile_picture_url', '') or "profile_placeholder"
        }
        for u in users
    ]

    logs = GoalProgressLog.query.filter_by(goals_id=goal.id).order_by(GoalProgressLog.timestamp.desc()).limit(20).all()
    a_latest_progress = [log.as_dict() for log in logs]

    # --- PATCH: Use correct filled_quota for non-Recruiting goals ---
    result = goal.as_dict()
    if goal.portals_id:
        portal = Portal.query.get(goal.portals_id)
        result["portalName"] = portal.name if portal else None
    else:
        result["portalName"] = None
    if goal.goal_type == "Recruiting":
        result["filled_quota"] = GoalTeam.query.filter_by(goals_id=goal.id, confirmed=1).count()
    else:
        latest_log = GoalProgressLog.query.filter_by(goals_id=goal.id).order_by(GoalProgressLog.timestamp.desc()).first()
        result["filled_quota"] = latest_log.value if latest_log else 0
        result["progress"] = round(result["filled_quota"] / result["quota"], 2) if result.get("quota") else 0
        result["progress_percent"] = round(100 * result["filled_quota"] / result["quota"]) if result.get("quota") else 0
        result["valueString"] = str(int(result["filled_quota"]))

    result["team"] = team
    result["aLatestProgress"] = a_latest_progress
    result["chartData"] = chart_data  # <-- PATCH: Use correct chart data

    return jsonify({'result': result})

# --- POST: Create Goal ---
@goals_bp.route('/create', methods=['POST'])
@jwt_required
def api_create_goal():
    data = request.json
    user_id = g.current_user.id
    if not user_id:
        return jsonify({'error': 'Login error!'}), 401

    required_fields = ['title', 'description', 'goal_type', 'reporting_increments_id', 'quota']
    for field in required_fields:
        if not data.get(field):
            return jsonify({'error': f'{field} required!'}), 400

    goal_type = data.get('goal_type')
    metric = data.get('metric')
    quota = float(data.get('quota', 100))
    if quota < 1:
        return jsonify({'error': 'quota < 1'}), 400
    lead_id = data.get('lead_id')
    if lead_id:
        if not User.query.get(lead_id):
            return jsonify({'error': 'Wrong lead_id'}), 400

    if goal_type == "Other":
        if not metric or not goal_type:
            return jsonify({'error': 'Custom goal_type and metric required for Other'}), 400
    else:
        metric = GOAL_TYPE_METRIC_MAP.get(goal_type)
        if not metric:
            return jsonify({'error': 'Invalid goal_type'}), 400

    portals_id = data.get('portals_id')
    if not portals_id or str(portals_id).lower() in ['none', '', 'null', '0']:
        portals_id = None
    else:
        try:
            portals_id = int(portals_id)
        except (TypeError, ValueError):
            return jsonify({'error': 'portals_id must be an integer or null'}), 400
        if not db.session.query(Portal).filter_by(id=portals_id).first():
            return jsonify({'error': 'Invalid portals_id'}), 400

    goal = Goal(
        title=data['title'],
        users_id=user_id,
        description=data['description'],
        portals_id=portals_id,
        quota=quota,
        goal_type=goal_type,
        metric=metric,
        rep_commission=data.get('rep_commission'),
        reporting_increments_id=data['reporting_increments_id'],
        lead_id=lead_id
    )
    db.session.add(goal)
    db.session.commit()
    team = GoalTeam(users_id1=user_id, users_id2=user_id, goals_id=goal.id, confirmed=1)
    db.session.add(team)
    db.session.commit()
    # Only create initial progress log for Recruiting goals
    if goal_type == "Recruiting":
        progress_log = GoalProgressLog(
            users_id=user_id,
            goals_id=goal.id,
            added_value=1.0,
            note="Goal created",
            value=1.0
        )
        db.session.add(progress_log)
        db.session.commit()
    return jsonify({'result': goal.as_dict()})

@goals_bp.route('/reporting_increments', methods=['GET'])
@jwt_required
def get_reporting_increments():
    increments = ReportingIncrement.query.all()
    result = [{"id": inc.id, "title": inc.title} for inc in increments]
    return jsonify({"reportingIncrements": result})

# --- POST: Edit Goal ---
@goals_bp.route('/edit', methods=['POST'])
@jwt_required
def api_edit_goal():
    data = request.json
    user_id = g.current_user.id
    goal_id = data.get('goals_id')
    if not user_id:
        return jsonify({'error': 'Login error!'}), 401
    if not goal_id:
        return jsonify({'error': 'goals_id required!'}), 400
    goal = Goal.query.get(goal_id)
    if not goal:
        return jsonify({'error': "Goal not found"}), 404
    if not check_permission(goal, user_id):
        return jsonify({'error': "Permission denied."}), 403

    editable_fields = [
        'title', 'goal_type', 'metric', 'rep_commission', 'lead_id',
        'description', 'reporting_increments_id', 'quota', 'portals_id'
    ]
    for field in editable_fields:
        if field in data and data[field] is not None:
            if field == 'quota' and float(data[field]) < 1:
                return jsonify({'error': 'quota < 1'}), 400
            if field == 'portals_id':
                portals_id = data[field]
                if not portals_id or str(portals_id).lower() in ['none', '', 'null', '0']:
                    setattr(goal, field, None)
                else:
                    try:
                        portals_id = int(portals_id)
                    except (TypeError, ValueError):
                        return jsonify({'error': 'portals_id must be an integer or null'}), 400
                    if not db.session.query(Portal).filter_by(id=portals_id).first():
                        return jsonify({'error': 'Invalid portals_id'}), 400
                    setattr(goal, field, portals_id)
            else:
                setattr(goal, field, data[field])
    db.session.commit()
    return jsonify({'result': goal.as_dict()})

# --- POST: Delete Goal ---
@goals_bp.route('/delete', methods=['POST'])
@jwt_required
def api_delete_goal():
    data = request.json
    user_id = g.current_user.id
    goal_id = data.get('goals_id')
    if not user_id:
        return jsonify({'error': 'Login error!'}), 401
    if not goal_id:
        return jsonify({'error': 'goals_id required!'}), 400
    goal = Goal.query.get(goal_id)
    if not goal:
        return jsonify({'error': "Goal not found"}), 404
    if not check_permission(goal, user_id):
        return jsonify({'error': "Permission denied."}), 403
    GoalTeam.query.filter_by(goals_id=goal.id).delete()
    GoalProgressLog.query.filter_by(goals_id=goal.id).delete()
    db.session.delete(goal)
    db.session.commit()
    return jsonify({'result': 'ok'})