# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app import db
from app.models.ValueMetric_Models.GoalTeam import GoalTeam
from app.models.People_Models.user import User
from app.models.ValueMetric_Models.Goal import Goal
from app.models.ValueMetric_Models.GoalProgressLog import GoalProgressLog
from app.utils.auth import jwt_required
from app.utils.notifications import send_fcm_notification  # Add this import

goals_bp = Blueprint('goal_team', __name__)

# --- GET: List all team members for a goal ---
@goals_bp.route('/<int:goal_id>/team', methods=['GET'])
@jwt_required
def get_goal_team(goal_id):
    team = GoalTeam.query.filter_by(goals_id=goal_id).all()
    result = [tm.as_dict() for tm in team]
    return jsonify({"team": result})

# --- POST: Invite or add users to the team ---
@goals_bp.route('/<int:goal_id>/team', methods=['POST'])
@jwt_required
def invite_goal_team(goal_id):
    data = request.json
    user_id = g.current_user.id
    users = data.get('users', [])
    results = {}
    
    # Get inviter and goal info for notification
    inviter = User.query.get(user_id)
    goal = Goal.query.get(goal_id)
    
    if not goal:
        return jsonify({"error": "Goal not found"}), 404
    
    for u_id in users:
        existing = GoalTeam.query.filter_by(goals_id=goal_id, users_id2=u_id).first()
        if existing:
            results[u_id] = "already invited or member"
        else:
            new_team = GoalTeam(goals_id=goal_id, users_id1=user_id, users_id2=u_id, confirmed=0)
            db.session.add(new_team)
            results[u_id] = "invited"
            
            # Send push notification to the invited user
            invited_user = User.query.get(u_id)
            if invited_user and invited_user.device_token:
                try:
                    title = f"New Goal Team Invite"
                    body = f"{inviter.full_name} invited you to join '{goal.title}'"
                    
                    # Include relevant data for app routing
                    data = {
                        "type": "goal_team_invite",
                        "goal_id": str(goal_id),
                        "inviter_id": str(user_id)
                    }
                    
                    print(f"Sending goal team invite notification to user {u_id}")
                    send_fcm_notification(
                        invited_user.device_token,
                        title=title,
                        body=body,
                        data=data
                    )
                except Exception as e:
                    print(f"Error sending goal team invite notification: {e}")
    
    db.session.commit()
    # Return updated team list
    team = GoalTeam.query.filter_by(goals_id=goal_id).all()
    return jsonify({"result": results, "team": [tm.as_dict() for tm in team]})

# --- PATCH: Accept, decline, or mark invites as read ---
@goals_bp.route('/<int:goal_id>/team', methods=['PATCH'])
@jwt_required
def update_goal_team(goal_id):
    data = request.json
    user_id = g.current_user.id
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
            # --- Add progress log for Recruiting goals ---
            goal = Goal.query.get(goal_id)
            if goal and goal.goal_type == "Recruiting":
                # Only add if not already present for this user/goal
                existing_log = GoalProgressLog.query.filter_by(goals_id=goal_id, users_id=u_id).first()
                if not existing_log:
                    progress_log = GoalProgressLog(
                        users_id=u_id,
                        goals_id=goal_id,
                        added_value=1.0,
                        note="Joined team",
                        value=1.0
                    )
                    db.session.add(progress_log)
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
@goals_bp.route('/<int:goal_id>/team/<int:user_id>', methods=['DELETE'])
@jwt_required
def remove_goal_team(goal_id, user_id):
    session_user_id = g.current_user.id
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

# --- GET: Fetch all pending invites for the current user ---
@goals_bp.route('/pending_invites', methods=['GET'])
@jwt_required
def get_pending_invites():
    user_id = g.current_user.id

    # Query for all pending invites where the current user is the invitee
    pending_invites = (
        db.session.query(GoalTeam, Goal, User)
        .join(Goal, GoalTeam.goals_id == Goal.id)
        .join(User, GoalTeam.users_id1 == User.id)
        .filter(GoalTeam.users_id2 == user_id)
        .filter(GoalTeam.confirmed == 0)
        .all()
    )

    # Format the results to match the expected Swift model
    result = [{
        "id": team.id,
        "goals_id": team.goals_id,
        "users_id1": team.users_id1,
        "users_id2": team.users_id2,
        "confirmed": team.confirmed,
        "read1": team.read1,
        "read2": team.read2,
        "timestamp": team.timestamp.isoformat() if team.timestamp else None,
        "goalTitle": goal.title,
        "inviterName": f"{user.fname or ''} {user.lname or ''}".strip(),
        "inviterPhotoURL": getattr(user, "profile_photo_url", None)
    } for team, goal, user in pending_invites]

    return jsonify({"invites": result})