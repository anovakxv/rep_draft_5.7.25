# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app import db, socketio  # added socketio
from app.models.ValueMetric_Models.GoalTeam import GoalTeam
from app.models.People_Models.user import User
from app.models.ValueMetric_Models.Goal import Goal
from app.models.ValueMetric_Models.GoalProgressLog import GoalProgressLog
from app.utils.auth import jwt_required
from app.utils.notifications import send_notification
import time

goals_bp = Blueprint('goal_team', __name__)

# Cache storage for pending invites
_invite_cache = {}  # {user_id: {"data": result, "timestamp": time, "count": hits}}
_CACHE_TTL = 120  # 2 minutes between full DB queries

# Helper function to invalidate invite cache for a user
def invalidate_invite_cache(user_id):
    """Remove a user's cache entry when their invites change"""
    if user_id in _invite_cache:
        del _invite_cache[user_id]
        print(f"Cache invalidated for user {user_id} due to invite changes")

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

            # Push notification (FCM)
            invited_user = User.query.get(u_id)
            if invited_user and invited_user.device_token:
                try:
                    title = "New Goal Team Invite"
                    body = f"{inviter.full_name} invited you to join '{goal.title}'"
                    payload = {
                        "type": "goal_team_invite",
                        "goal_id": str(goal_id),
                        "inviter_id": str(user_id)
                    }
                    print(f"Sending goal team invite notification to user {u_id}")
                    send_notification(
                        u_id,  # The recipient's user ID
                        "goal_invite",  # Notification type
                        title=title,
                        body=body,
                        data=payload
                    )
                except Exception as e:
                    print(f"Error sending goal team invite notification: {e}")

            # Realtime socket event to invitee
            try:
                socketio.emit(
                    "goal_team_invite",
                    {
                        "goal_id": goal_id,
                        "inviter_id": user_id,
                        "invitee_id": u_id,
                        "goal_title": goal.title,
                        "inviter_name": inviter.full_name if inviter else ""
                    },
                    room=f"user_{u_id}"
                )
            except Exception as e:
                print(f"Socket emit goal_team_invite error: {e}")

    db.session.commit()
    
    # Invalidate cache for all invitees
    for u_id in users:
        invalidate_invite_cache(u_id)

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
        if action in ['accept', 'decline', 'mark_as_read'] and user_id != u_id:
            results[u_id] = "permission denied"
            continue

        if action == 'accept':
            team.confirmed = 1
            team.read2 = True
            results[u_id] = "accepted"
            goal = Goal.query.get(goal_id)
            if goal and goal.goal_type == "Recruiting":
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

    team = GoalTeam.query.filter_by(goals_id=goal_id).all()

    # Socket updates (notify each invitee + inviter)
    try:
        # Find inviter_id for this goal (all team rows share same inviter)
        inviter_id = None
        if team:
            inviter_id = team[0].users_id1

        for u_id, status in results.items():
            socketio.emit(
                "goal_team_invite_update",
                {
                    "goal_id": goal_id,
                    "invitee_id": u_id,
                    "action": action,
                    "status": status
                },
                room=f"user_{u_id}"
            )
        # Also notify current user (inviter or invitee) for UI sync
        socketio.emit(
            "goal_team_invite_update",
            {
                "goal_id": goal_id,
                "action": action,
                "bulk": results
            },
            room=f"user_{user_id}"
        )
        # NEW: Always notify inviter if different (ensures inviter UI refresh)
        if inviter_id and inviter_id != user_id:
            socketio.emit(
                "goal_team_invite_update",
                {
                    "goal_id": goal_id,
                    "action": action,
                    "bulk": results
                },
                room=f"user_{inviter_id}"
            )
    except Exception as e:
        print(f"Socket emit goal_team_invite_update error: {e}")
    
    # Invalidate cache for the current user
    invalidate_invite_cache(user_id)
    # Invalidate cache for the inviter if different
    if inviter_id and inviter_id != user_id:
        invalidate_invite_cache(inviter_id)

    return jsonify({"result": results, "team": [tm.as_dict() for tm in team]})

# --- DELETE: Remove or leave team ---
@goals_bp.route('/<int:goal_id>/team/<int:user_id>', methods=['DELETE'])
@jwt_required
def remove_goal_team(goal_id, user_id):
    session_user_id = g.current_user.id
    team = GoalTeam.query.filter_by(goals_id=goal_id, users_id2=user_id).first()
    if not team:
        return jsonify({"error": "not found"}), 404
    if session_user_id != user_id and session_user_id != team.users_id1:
        return jsonify({"error": "permission denied"}), 403

    inviter_id = team.users_id1
    invitee_id = team.users_id2

    db.session.delete(team)
    db.session.commit()

    # Emit removal update (optional consistency)
    try:
        payload = {
            "goal_id": goal_id,
            "invitee_id": invitee_id,
            "action": "removed",
            "status": "removed"
        }
        socketio.emit("goal_team_invite_update", payload, room=f"user_{invitee_id}")
        socketio.emit("goal_team_invite_update", payload, room=f"user_{inviter_id}")
    except Exception as e:
        print(f"Socket emit goal_team_invite_update (remove) error: {e}")
    
    # Invalidate caches for both invitee and inviter
    invalidate_invite_cache(invitee_id)
    invalidate_invite_cache(inviter_id)

    team = GoalTeam.query.filter_by(goals_id=goal_id).all()
    return jsonify({"result": "removed", "team": [tm.as_dict() for tm in team]})

# --- GET: Fetch all pending invites for the current user ---
@goals_bp.route('/pending_invites', methods=['GET'])
@jwt_required
def get_pending_invites():
    user_id = g.current_user.id
    current_time = time.time()
    
    # Check if we have cached data and if it's recent
    if user_id in _invite_cache:
        cache_entry = _invite_cache[user_id]
        time_since_last_query = current_time - cache_entry["timestamp"]
        
        # Increment request count for analytics
        cache_entry["count"] = cache_entry.get("count", 0) + 1
        
        # If cache is fresh, return it immediately
        if time_since_last_query < _CACHE_TTL:
            # Log excessive requests (optional)
            if cache_entry["count"] % 10 == 0:  # Log every 10th hit
                print(f"⚠️ High frequency invite polling: user {user_id}, {cache_entry['count']} requests in {time_since_last_query:.1f}s")
            return jsonify({"invites": cache_entry["data"]})
    
    # Cache miss or expired, perform database query
    pending_invites = (
        db.session.query(GoalTeam, Goal, User)
        .join(Goal, GoalTeam.goals_id == Goal.id)
        .join(User, GoalTeam.users_id1 == User.id)
        .filter(GoalTeam.users_id2 == user_id)
        .filter(GoalTeam.confirmed == 0)
        .all()
    )

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

    # Update cache
    _invite_cache[user_id] = {
        "data": result,
        "timestamp": current_time,
        "count": 1
    }
    
    # Clean old cache entries periodically
    if current_time % 60 < 1:  # ~once per minute
        clean_old_cache_entries()
    
    return jsonify({"invites": result})

def clean_old_cache_entries():
    """Remove cache entries older than 10 minutes"""
    current_time = time.time()
    stale_threshold = current_time - 600  # 10 minutes
    
    stale_keys = [
        user_id for user_id, entry in _invite_cache.items() 
        if entry["timestamp"] < stale_threshold
    ]
    
    for key in stale_keys:
        del _invite_cache[key]

# --- POST: Mark all pending invites as read for current user ---
@goals_bp.route('/pending_invites/mark_read', methods=['POST'])
@jwt_required
def mark_all_pending_invites_read():
    user_id = g.current_user.id
    invites = GoalTeam.query.filter_by(users_id2=user_id, confirmed=0).all()
    if not invites:
        return jsonify({"result": "none"}), 200

    changed_goal_ids = set()
    inviter_ids = set()
    for inv in invites:
        if not inv.read2:
            inv.read2 = True
        changed_goal_ids.add(inv.goals_id)
        inviter_ids.add(inv.users_id1)

    db.session.commit()

    # Emit update to current user
    try:
        socketio.emit(
            "goal_team_invite_update",
            {
                "action": "mark_as_read",
                "goal_ids": list(changed_goal_ids)
            },
            room=f"user_{user_id}"
        )
        # Notify inviters (they may want to show read status)
        for inviter_id in inviter_ids:
            if inviter_id != user_id:
                socketio.emit(
                    "goal_team_invite_update",
                    {
                        "action": "invitee_read",
                        "invitee_id": user_id,
                        "goal_ids": list(changed_goal_ids)
                    },
                    room=f"user_{inviter_id}"
                )
    except Exception as e:
        print(f"Socket emit mark_read error: {e}")
    
    # Invalidate cache for current user
    invalidate_invite_cache(user_id)
    # Invalidate cache for all inviters
    for inviter_id in inviter_ids:
        if inviter_id != user_id:
            invalidate_invite_cache(inviter_id)

    return jsonify({"result": "ok", "updated": len(invites)})