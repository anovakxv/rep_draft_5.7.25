# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app import db
from app.models.ValueMetric_Models.Goal import Goal
from app.models.ValueMetric_Models.GoalTeam import GoalTeam
from app.models.ValueMetric_Models.GoalProgressLog import GoalProgressLog
from app.models.People_Models.Messaging_Models.GroupChatUsers import ChatsUsers
from app.models.People_Models.Messaging_Models.Group_Messages import GroupMessage
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

    # Track event portal joins for confirmation email (populated during loop, sent after commit)
    event_reg_goals = []  # list of Goal objects for event portals successfully joined

    # Collect post-commit emits safely (target_id, goal_id, status)
    emits = []
    try:
        from app.utils.notifications import emit_goal_team_invite_update  # optional, may not exist everywhere
    except Exception:
        emit_goal_team_invite_update = None  # type: ignore

    for goal_id in goals_ids:
        goal = Goal.query.get(goal_id)
        if not goal:
            results[goal_id] = "Goal not found"
            continue

        team = GoalTeam.query.filter_by(goals_id=goal_id, users_id2=user_id).first()

        if todo == 'join':
            _joined_ok = False  # flag to track successful join for email
            if team and team.confirmed == 1:
                results[goal_id] = "Already a member"
            elif team and team.confirmed == 0:
                # User has pending invite - accept it automatically
                team.confirmed = 1
                team.read2 = True
                results[goal_id] = "ok"
                _joined_ok = True
                # --- Add progress log for Recruiting goals ---
                if getattr(goal, "goal_type", None) == "Recruiting":
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
                # Notify inviter that invite was accepted
                if emit_goal_team_invite_update:
                    try:
                        inviter_id = team.users_id1
                        if inviter_id and inviter_id != user_id:
                            emits.append((int(inviter_id), int(goal_id), "accepted"))
                    except Exception:
                        pass
            elif team and team.confirmed == -1:
                # User previously declined - allow them to join now
                team.confirmed = 1
                team.read2 = True
                results[goal_id] = "ok"
                _joined_ok = True
                # --- Add progress log for Recruiting goals ---
                if getattr(goal, "goal_type", None) == "Recruiting":
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
                # Notify inviter
                if emit_goal_team_invite_update:
                    try:
                        inviter_id = team.users_id1
                        if inviter_id and inviter_id != user_id:
                            emits.append((int(inviter_id), int(goal_id), "accepted"))
                    except Exception:
                        pass
            else:
                new_team = GoalTeam(goals_id=goal_id, users_id1=user_id, users_id2=user_id, confirmed=1)
                db.session.add(new_team)
                results[goal_id] = "ok"
                _joined_ok = True
                # --- PATCH: Add progress log for Recruiting goals ---
                if getattr(goal, "goal_type", None) == "Recruiting":
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

                # Optional: notify a likely inviter/owner that this user joined (safe best-effort)
                if emit_goal_team_invite_update:
                    try:
                        inviter_id = (
                            getattr(goal, "users_id", None) or
                            getattr(goal, "created_by", None) or
                            getattr(goal, "owner_id", None)
                        )
                        if inviter_id and inviter_id != user_id:
                            emits.append((int(inviter_id), int(goal_id), "accepted"))
                    except Exception:
                        pass

            # Auto-add new member to the goal's canonical group chat
            if _joined_ok and goal.chats_id:
                already_member = ChatsUsers.query.filter_by(
                    chats_id=goal.chats_id, users_id=user_id
                ).first()
                if not already_member:
                    db.session.add(ChatsUsers(users_id=user_id, chats_id=goal.chats_id))
                    user_obj = g.current_user
                    full_name = getattr(user_obj, 'full_name', None) or \
                        f"{getattr(user_obj, 'fname', '') or ''} {getattr(user_obj, 'lname', '') or ''}".strip() or \
                        "A new member"
                    db.session.add(GroupMessage(
                        chat_id=goal.chats_id,
                        sender_id=user_id,
                        text=f"{full_name} has joined the Team."
                    ))

            # Collect for event registration email (checked after commit)
            if _joined_ok and goal.goal_type == 'Recruiting' and goal.portals_id:
                event_reg_goals.append(goal)

        elif todo == 'leave':
            if not team:
                results[goal_id] = "Not a member"
            else:
                db.session.delete(team)
                results[goal_id] = "ok"
                # Optional: notify a likely inviter/owner that this user left (safe best-effort)
                if emit_goal_team_invite_update:
                    try:
                        inviter_id = (
                            getattr(goal, "users_id", None) or
                            getattr(goal, "created_by", None) or
                            getattr(goal, "owner_id", None)
                        )
                        if inviter_id and inviter_id != user_id:
                            emits.append((int(inviter_id), int(goal_id), "updated"))
                    except Exception:
                        pass
                # Optionally: remove progress log, send notifications, etc.

    db.session.commit()

    # --- Send event registration confirmation emails (best-effort, non-blocking) ---
    if event_reg_goals:
        try:
            from app.utils.mail_utils import send_event_registration_email
            from app.models.Purpose_Models.Portal import Portal
            user = g.current_user
            for goal in event_reg_goals:
                try:
                    portal = Portal.query.get(goal.portals_id)
                    if portal and portal.portal_type == 'event':
                        send_event_registration_email(user, portal)
                except Exception as e:
                    print(f"[Event Email] Failed for goal {goal.id}: {e}")
        except Exception as e:
            print(f"[Event Email] Import error: {e}")

    # --- PATCH: Return updated team size for each goal ---
    team_sizes = {}
    for goal_id in goals_ids:
        team_sizes[goal_id] = GoalTeam.query.filter_by(goals_id=goal_id, confirmed=1).count()

    # Post-commit socket notifications (best-effort, non-blocking)
    if 'emit_goal_team_invite_update' in locals() and emit_goal_team_invite_update:
        for target_id, gid, status in emits:
            try:
                emit_goal_team_invite_update(
                    target_id=target_id,
                    goal_id=gid,
                    actor_id=user_id,
                    status=status
                )
            except Exception as e:
                print(f"[Invites Socket] emit update failed for goal {gid}: {e}")

    return jsonify({'result': results, 'team_sizes': team_sizes})