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
from app.utils.auth import jwt_required

goals_bp = Blueprint('goals', __name__)

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

# --- GET: Goal Details ---
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

    # Patch: Fix AttributeError in as_dict's chart_data
    # Patch the Goal instance to use correct chart_data ordering
    def patched_chart_data(self, increment='month', num_periods=4):
        from app.models.ValueMetric_Models.GoalProgressLog import GoalProgressLog
        logs = self.progress_logs.order_by(GoalProgressLog.timestamp.asc()).all()
        from collections import defaultdict
        data = defaultdict(int)
        for log in logs:
            if log.timestamp:
                if increment == 'month':
                    label = log.timestamp.strftime('%b')
                elif increment == 'week':
                    label = f"W{log.timestamp.isocalendar()[1]}"
                elif increment == 'day':
                    label = log.timestamp.strftime('%d %b')
                else:
                    label = log.timestamp.strftime('%b')
                data[label] += log.added_value or 0
        items = list(data.items())[-num_periods:]
        return [
            {"value": value, "label": label, "color": "#00FF00"}
            for label, value in items
        ]
    goal.chart_data = patched_chart_data.__get__(goal, Goal)

    return jsonify({'result': goal.as_dict(include_team=True, include_progress_logs=True)})

# --- POST: Create Goal ---
@goals_bp.route('/create', methods=['POST'])
@jwt_required
def api_create_goal():
    data = request.json
    user_id = g.current_user.id
    if not user_id:
        return jsonify({'error': 'Login error!'}), 401

    # Add "title" to required fields
    required_fields = ['title', 'description', 'goal_type', 'reporting_increments_id', 'quota']
    for field in required_fields:
        if not data.get(field):
            return jsonify({'error': f'{field} required!'}), 400

    goal_type = data.get('goal_type')
    metric = data.get('metric')
    quota = int(data.get('quota', 100))
    if quota < 1:
        return jsonify({'error': 'quota < 1'}), 400
    lead_id = data.get('lead_id')
    if lead_id:
        if not User.query.get(lead_id):
            return jsonify({'error': 'Wrong lead_id'}), 400

    # Determine metric based on goal_type
    if goal_type == "Other":
        if not metric or not goal_type:
            return jsonify({'error': 'Custom goal_type and metric required for Other'}), 400
    else:
        metric = GOAL_TYPE_METRIC_MAP.get(goal_type)
        if not metric:
            return jsonify({'error': 'Invalid goal_type'}), 400

    portals_id = data.get('portals_id')
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
    progress_log = GoalProgressLog(
        users_id=user_id,
        goals_id=goal.id,
        added_value=1,
        note="Goal created",
        value=1
    )
    db.session.add(progress_log)
    db.session.commit()
    return jsonify({'result': goal.as_dict()})

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
            if field == 'quota' and int(data[field]) < 1:
                return jsonify({'error': 'quota < 1'}), 400
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
    # Delete related data
    GoalTeam.query.filter_by(goals_id=goal.id).delete()
    GoalProgressLog.query.filter_by(goals_id=goal.id).delete()
    db.session.delete(goal)
    db.session.commit()
    return jsonify({'result': 'ok'})
