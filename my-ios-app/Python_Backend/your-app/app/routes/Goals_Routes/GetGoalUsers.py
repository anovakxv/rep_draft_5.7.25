# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app.models.ValueMetric_Models.GoalTeam import GoalTeam
from app.models.People_Models.user import User
from app.utils.auth import jwt_required

goals_bp = Blueprint('get_goal_users', __name__)

@goals_bp.route('/users', methods=['GET'])
@jwt_required
def api_get_goal_users():
    goal_id = request.args.get('goals_id', type=int)
    confirmed = request.args.get('confirmed')
    offset = request.args.get('offset', default=0, type=int)
    limit = request.args.get('limit', default=50, type=int)

    if not goal_id:
        return jsonify({'error': 'goals_id is empty!'}), 400
    if offset < 0:
        return jsonify({'error': 'offset is wrong!'}), 400
    if limit > 4096:
        return jsonify({'error': 'limit should be <= 4096'}), 400

    query = GoalTeam.query.filter_by(goals_id=goal_id)
    if confirmed is not None:
        query = query.filter_by(confirmed=int(confirmed))
    team_members = query.offset(offset).limit(limit).all()

    user_ids = [member.users_id2 for member in team_members]
    users = User.query.filter(User.id.in_(user_ids)).all()
    users_dict = {u.id: u for u in users}

    result = []
    for member in team_members:
        user = users_dict.get(member.users_id2)
        if user:
            result.append({
                'id': user.id,
                'username': getattr(user, 'username', None),
                'fname': getattr(user, 'fname', None),
                'lname': getattr(user, 'lname', None),
                'email': getattr(user, 'email', None),
                'about': getattr(user, 'about', None),
                'phone': getattr(user, 'phone', None),
                'cities_id': getattr(user, 'cities_id', None),
                'users_types_id': getattr(user, 'users_types_id', None),
                'confirmed': member.confirmed,
                'team_id': member.id,
                'team_read1': member.read1,
                'team_read2': member.read2,
                'team_timestamp': member.timestamp.isoformat() if member.timestamp else None
            })

    return jsonify({'result': result})
