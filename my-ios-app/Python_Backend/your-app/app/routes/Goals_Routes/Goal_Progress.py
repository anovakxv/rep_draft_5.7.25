# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app import db
from app.models.ValueMetric_Models.Goal import Goal
from app.models.ValueMetric_Models.GoalProgressLog import GoalProgressLog
from app.models.ValueMetric_Models.GoalTeam import GoalTeam
from app.utils.auth import jwt_required

goals_bp = Blueprint('goal_progress', __name__)

# --- GET: List progress logs for a goal ---
@goals_bp.route('/<int:goal_id>/progress', methods=['GET'])
@jwt_required
def get_goal_progress(goal_id):
    logs = GoalProgressLog.query.filter_by(goals_id=goal_id).order_by(GoalProgressLog.timestamp.desc()).all()
    result = [log.as_dict() for log in logs]
    return jsonify({"progressLogs": result})

# --- POST: Add a progress log (update filled_quota) ---
@goals_bp.route('/<int:goal_id>/progress', methods=['POST'])
@jwt_required
def add_goal_progress(goal_id):
    data = request.json
    user_id = g.current_user.id
    added_value = data.get('added_value')
    note = data.get('note', '')

    if not user_id:
        return jsonify({'error': 'Login error!'}), 401
    try:
        added_value = float(added_value)
    except (TypeError, ValueError):
        return jsonify({'error': 'added_value must be a number!'}), 400
    if added_value is None:
        return jsonify({'error': 'added_value required!'}), 400
    if added_value == 0:
        return jsonify({'error': 'added_value must not be zero!'}), 400

    goal = Goal.query.get(goal_id)
    if not goal:
        return jsonify({'error': 'Goal not found'}), 404

    # --- PATCH: Prevent manual progress for Recruiting goals ---
    if goal.goal_type == "Recruiting":
        return jsonify({'error': 'Recruiting goals update automatically. Manual progress is not allowed.'}), 400

    # Permission: Only owner or confirmed team member can update
    is_owner = goal.users_id == user_id
    is_team_member = GoalTeam.query.filter_by(goals_id=goal_id, users_id2=user_id, confirmed=1).count() > 0
    if not (is_owner or is_team_member):
        return jsonify({'error': 'Permission denied'}), 403

    # Prevent update for internal goal types (1, 2, 5)
    if hasattr(goal, "goal_types_id") and str(goal.goal_types_id) in ['1', '2', '5']:
        return jsonify({'error': 'INTERNAL GOALS (No Update Goal Form Needed)'}), 400

    # Add progress log
    progress_log = GoalProgressLog(
        users_id=user_id,
        goals_id=goal_id,
        added_value=added_value,
        note=note,
        value=(goal.filled_quota or 0) + added_value
    )
    db.session.add(progress_log)

    # Update goal's filled_quota
    goal.filled_quota = (goal.filled_quota or 0) + added_value
    db.session.commit()

    return jsonify({'result': goal.as_dict(card_mode=True)})

# --- PATCH: Edit a progress log ---
@goals_bp.route('/<int:goal_id>/progress/<int:log_id>', methods=['PATCH'])
@jwt_required
def edit_goal_progress(goal_id, log_id):
    data = request.json
    user_id = g.current_user.id
    log = GoalProgressLog.query.filter_by(id=log_id, goals_id=goal_id).first()
    if not log:
        return jsonify({'error': 'Progress log not found'}), 404
    if log.users_id != user_id:
        return jsonify({'error': 'Permission denied'}), 403

    goal = Goal.query.get(goal_id)
    # --- PATCH: Prevent manual progress edit for Recruiting goals ---
    if goal and goal.goal_type == "Recruiting":
        return jsonify({'error': 'Recruiting goals update automatically. Manual progress is not allowed.'}), 400

    diff = 0
    if 'note' in data:
        log.note = data['note']
    if 'added_value' in data:
        try:
            new_value = float(data['added_value'])
        except (TypeError, ValueError):
            return jsonify({'error': 'added_value must be a number!'}), 400
        diff = new_value - log.added_value
        log.added_value = new_value
        log.value += diff
        # Update goal's filled_quota accordingly
        if goal:
            goal.filled_quota = max(0, (goal.filled_quota or 0) + diff)
    db.session.commit()
    goal = Goal.query.get(goal_id)
    return jsonify({'result': goal.as_dict(card_mode=True)})

# --- DELETE: Remove a progress log ---
@goals_bp.route('/<int:goal_id>/progress/<int:log_id>', methods=['DELETE'])
@jwt_required
def delete_goal_progress(goal_id, log_id):
    user_id = g.current_user.id
    log = GoalProgressLog.query.filter_by(id=log_id, goals_id=goal_id).first()
    if not log:
        return jsonify({'error': 'Progress log not found'}), 404
    if log.users_id != user_id:
        return jsonify({'error': 'Permission denied'}), 403

    goal = Goal.query.get(goal_id)
    # --- PATCH: Prevent manual progress delete for Recruiting goals ---
    if goal and goal.goal_type == "Recruiting":
        return jsonify({'error': 'Recruiting goals update automatically. Manual progress is not allowed.'}), 400

    # Adjust goal's filled_quota
    if goal:
        goal.filled_quota = max(0, (goal.filled_quota or 0) - log.added_value)
    db.session.delete(log)
    db.session.commit()
    goal = Goal.query.get(goal_id)
    return jsonify({'result': goal.as_dict(card_mode=True)})