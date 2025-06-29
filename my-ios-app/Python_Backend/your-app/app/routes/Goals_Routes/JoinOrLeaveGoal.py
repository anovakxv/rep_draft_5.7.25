# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, session
from app import db
from app.models.ValueMetric_Models.Goal import Goal
from app.models.ValueMetric_Models.GoalTeam import GoalTeam

goals_bp = Blueprint('join_leave_goal', __name__)

@goals_bp.route('/join_leave', methods=['POST'])
def api_join_leave_goal():
    data = request.json
    user_id = session.get('user_id')
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
                # Optionally: log progress, send notifications, etc.
        elif todo == 'leave':
            if not team:
                results[goal_id] = "Not a member"
            else:
                db.session.delete(team)
                results[goal_id] = "ok"
                # Optionally: remove progress log, send notifications, etc.

    db.session.commit()
    return jsonify({'result': results})
