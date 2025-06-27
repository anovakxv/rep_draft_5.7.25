# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, session
from app import db
from app.models.ValueMetric_Models.GoalTeam import GoalTeam
from app.models.People_Models.user import User

goals_bp = Blueprint('goals', __name__)

# --- GET: List all team members for a goal ---
@goals_bp.route('/api/goals/<int:goal_id>/team', methods=['GET'])
def get_goal_team(goal_id):
    team = GoalTeam.query.filter_by(goals_id=goal_id).all()
    result = [tm.as_dict() for tm in team]
    return jsonify({"team": result})

# --- POST: Invite or add users to the team ---
@goals_bp.route('/api/goals/<int:goal_id>/team', methods=['POST'])
def invite_goal_team(goal_id):
    data = request.json
    user_id = session.get('user_id')
    users = data.get('users', [])
    results = {}
    for u_id in users:
        existing = GoalTeam.query.filter_by(goals_id=goal_id, users_id2=u_id).first()
        if existing:
            results[u_id] = "already invited or member"
        else:
            new_team = GoalTeam(goals_id=goal_id, users_id1=user_id, users_id2=u_id, confirmed=0)
            db.session.add(new_team)
            results[u_id] = "invited"
    db.session.commit()
    # Return updated team list
    team = GoalTeam.query.filter_by(goals_id=goal_id).all()
    return jsonify({"result": results, "team": [tm.as_dict() for tm in team]})

# --- PATCH: Accept, decline, or mark invites as read ---
@goals_bp.route('/api/goals/<int:goal_id>/team', methods=['PATCH'])
def update_goal_team(goal_id):
    data = request.json
    user_id = session.get('user_id')
    action = data.get('action')  # 'accept', 'decline', 'mark_as_read'
    users = data.get('users', [])
    results = {}
    for u_id in users:
        team = GoalTeam.query.filter_by(goals_id=goal_id, users_id2=u_id).first()
        if not team:
            results[u_id] = "not found"
            continue
        # Permission: Only the invitee can accept/decline/mark as read for themselves
        if action in ['accept', 'decline', 'mark_as_read'] and user_id != u_id:
            results[u_id] = "permission denied"
            continue
        if action == 'accept':
            team.confirmed = 1
            team.read2 = True
            results[u_id] = "accepted"
        elif action == 'decline':
            team.confirmed = -1
            team.read2 = True
            results[u_id] = "declined"
        elif action == 'mark_as_read':
            if team.users_id1 == user_id:
                team.read1 = True
            if team.users_id2 == user_id:
                team.read2 = True
            results[u_id] = "marked as read"
    db.session.commit()
    # Return updated team list
    team = GoalTeam.query.filter_by(goals_id=goal_id).all()
    return jsonify({"result": results, "team": [tm.as_dict() for tm in team]})

# --- DELETE: Remove or leave team ---
@goals_bp.route('/api/goals/<int:goal_id>/team/<int:user_id>', methods=['DELETE'])
def remove_goal_team(goal_id, user_id):
    session_user_id = session.get('user_id')
    team = GoalTeam.query.filter_by(goals_id=goal_id, users_id2=user_id).first()
    if not team:
        return jsonify({"error": "not found"}), 404
    # Only the user themselves or the inviter can remove
    if session_user_id != user_id and session_user_id != team.users_id1:
        return jsonify({"error": "permission denied"}), 403
    db.session.delete(team)
    db.session.commit()
    # Return updated team list
    team = GoalTeam.query.filter_by(goals_id=goal_id).all()
    return jsonify({"result": "removed", "team": [tm.as_dict() for tm in team]})
