# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app import db
from app.models.ValueMetric_Models.Goal import Goal
from app.models.ValueMetric_Models.GoalTeam import GoalTeam
from app.models.ValueMetric_Models.GoalProgressLog import GoalProgressLog
from app.utils.auth import jwt_required

goals_bp = Blueprint('join_leave_goal', __name__)

@goals_bp.route('/join_leave', methods=['POST'])
@jwt_required
def api_join_leave_goal():
    data = request.json
    user_id = g.current_user.id
    goals_ids = data.get('aGoalsIDs', [])
    todo = data.get('todo')  # 'join' or 'leave'

    if not user_id:
        return jsonify({'error': 'Login error!'}), 401
    if not goals_ids or todo not in ['join', 'leave']:
        return jsonify({'error': 'Invalid request'}), 400

    results = {}
    for goal_id in goals_ids:
        goal = Goal.query.get(goal_id)
        if not goal:
            results[goal_id] = "Goal not found"
            continue

        team = GoalTeam.query.filter_by(goals_id=goal_id, users_id2=user_id).first()

        if todo == 'join':
            if team:
                results[goal_id] = "Already a member"
            else:
                new_team = GoalTeam(goals_id=goal_id, users_id1=user_id, users_id2=user_id, confirmed=1)
                db.session.add(new_team)
                results[goal_id] = "ok"
                # --- PATCH: Add progress log for Recruiting goals ---
                if goal.goal_type == "Recruiting":
                    existing_log = GoalProgressLog.query.filter_by(goals_id=goal_id, users_id=user_id).first()
                    if not existing_log:
                        progress_log = GoalProgressLog(
                            users_id=user_id,
                            goals_id=goal_id,
                            added_value=1.0,
                            note="Joined team",
                            value=1.0
                        )
                        db.session.add(progress_log)
        elif todo == 'leave':
            if not team:
                results[goal_id] = "Not a member"
            else:
                db.session.delete(team)
                results[goal_id] = "ok"
                # Optionally: remove progress log, send notifications, etc.

    db.session.commit()
    # --- PATCH: Return updated team size for each goal ---
    team_sizes = {}
    for goal_id in goals_ids:
        team_sizes[goal_id] = GoalTeam.query.filter_by(goals_id=goal_id, confirmed=1).count()
    return jsonify({'result': results, 'team_sizes': team_sizes})