# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, jsonify, g
from app import db
from app.models.ValueMetric_Models.GoalTeam import GoalTeam
from app.utils.auth import jwt_required

user_bp = Blueprint('get_total_counts', __name__)

@user_bp.route('/get_total_counts', methods=['GET'])
@jwt_required
def api_get_total_counts():
    user_id = g.current_user.id

    # Count unconfirmed goal team invites for this user
    invites_new = db.session.query(GoalTeam).filter(
        GoalTeam.users_id2 == user_id,
        GoalTeam.confirmed == 0
    ).count()

    return jsonify({'result': {'invites_new': invites_new}})
