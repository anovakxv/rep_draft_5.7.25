# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app.models.ValueMetric_Models.GoalProgressLog import GoalProgressLog
from app.models.ValueMetric_Models.Goal import Goal
from app.models.People_Models.user import User
from app.utils.auth import jwt_required

goals_bp = Blueprint('get_goal_feed', __name__)

@goals_bp.route('/progress_feed', methods=['GET'])
@jwt_required
def api_get_goals_progress_feed():
    goal_id = request.args.get('goals_id', type=int)
    offset = request.args.get('offset', default=0, type=int)
    limit = request.args.get('limit', default=50, type=int)

    if not goal_id:
        return jsonify({'error': 'goals_id is empty!'}), 400
    if offset < 0:
        return jsonify({'error': 'offset is wrong!'}), 400
    if limit > 4096:
        return jsonify({'error': 'limit should be <= 4096'}), 400

    goal = Goal.query.get(goal_id)
    if not goal:
        return jsonify({'error': 'Goal not found'}), 404

    logs = GoalProgressLog.query.filter_by(goals_id=goal_id)\
        .order_by(GoalProgressLog.timestamp.asc())\
        .offset(offset).limit(limit).all()

    users_dict = {}
    result = []
    previous_value = 0

    for log in logs:
        user = users_dict.get(log.users_id)
        if not user:
            user = User.query.get(log.users_id)
            users_dict[log.users_id] = user

        percent = round((log.value / goal.quota), 2) if goal.quota else 0
        percent = min(max(percent, 0), 1)
        sector_percent = round(((log.value - previous_value) / goal.quota), 2) if (log.value - previous_value) > 0 and goal.quota else percent

        result.append({
            'id': log.id,
            'users_id': log.users_id,
            'username': user.username if user else None,
            'added_value': log.added_value,
            'note': log.note,
            'value': log.value,
            'timestamp': log.timestamp.isoformat() if log.timestamp else None,
            'progress_total_percent': percent,
            'progress_sector_percent': sector_percent,
            'aAttachments': log.as_dict().get('aAttachments', [])
        })
        previous_value = log.value

    # Prepare users info for the feed
    users_info = [
        {
            'id': u.id,
            'username': getattr(u, 'username', None),
            'fname': getattr(u, 'fname', None),
            'lname': getattr(u, 'lname', None),
            'email': getattr(u, 'email', None)
        }
        for u in users_dict.values() if u
    ]

    # Add goal summary using as_dict()
    return jsonify({
        'goal': goal.as_dict(),
        'aData': result,
        'aUsers': users_info
    })
