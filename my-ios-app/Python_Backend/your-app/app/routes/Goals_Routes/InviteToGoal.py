# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app import db
from app.models.ValueMetric_Models.GoalPreInvite import GoalPreInvite
from app.utils.auth import jwt_required

goals_bp = Blueprint('goal_invite', __name__)

# --- POST: Add invites (email, phone) ---
@goals_bp.route('/<int:goal_id>/invites', methods=['POST'])
@jwt_required
def add_goal_invites(goal_id):
    data = request.json
    user_id = g.current_user.id
    emails = data.get('emails', [])
    phones = data.get('phones', [])
    results = {}

    # Email invites
    for email in emails:
        email = email.strip().lower()
        if not email:
            continue
        existing = GoalPreInvite.query.filter_by(goals_id=goal_id, type='email', identifier=email).first()
        if existing:
            results[email] = "already invited"
        else:
            invite = GoalPreInvite(users_id=user_id, goals_id=goal_id, type='email', identifier=email)
            db.session.add(invite)
            results[email] = "invited"

    # Phone invites
    for phone in phones:
        phone = phone.strip()
        if not phone:
            continue
        existing = GoalPreInvite.query.filter_by(goals_id=goal_id, type='phone', identifier=phone).first()
        if existing:
            results[phone] = "already invited"
        else:
            invite = GoalPreInvite(users_id=user_id, goals_id=goal_id, type='phone', identifier=phone)
            db.session.add(invite)
            results[phone] = "invited"

    db.session.commit()
    return jsonify({"result": results})

# --- DELETE: Remove invites (email, phone, fb) ---
@goals_bp.route('/<int:goal_id>/invites', methods=['DELETE'])
@jwt_required
def remove_goal_invites(goal_id):
    data = request.json
    user_id = g.current_user.id
    emails = data.get('emails', [])
    phones = data.get('phones', [])
    results = {}

    # Email invites
    for email in emails:
        email = email.strip().lower()
        deleted = GoalPreInvite.query.filter_by(goals_id=goal_id, type='email', identifier=email).delete()
        results[email] = "deleted" if deleted else "not found"

    # Phone invites
    for phone in phones:
        phone = phone.strip()
        deleted = GoalPreInvite.query.filter_by(goals_id=goal_id, type='phone', identifier=phone).delete()
        results[phone] = "deleted" if deleted else "not found"

    db.session.commit()
    return jsonify({"result": results})
