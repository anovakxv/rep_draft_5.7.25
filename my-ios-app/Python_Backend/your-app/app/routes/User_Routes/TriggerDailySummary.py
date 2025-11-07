# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: January 2025

"""
Admin route to manually trigger daily email summaries.
Used for testing before enabling automatic scheduler.
"""

from flask import Blueprint, jsonify, g
from app.utils.auth import jwt_required
from app.tasks.daily_email_summary import send_daily_summary

admin_bp = Blueprint('trigger_daily_summary', __name__)

@admin_bp.route('/trigger_daily_summary', methods=['POST'])
@jwt_required
def api_trigger_daily_summary():
    """
    Manual trigger for daily email summary (ADMIN ONLY).

    This endpoint allows admins to manually trigger the daily email summary
    job for testing purposes before enabling the automatic scheduler.

    Authorization:
        Requires JWT token and Admin user_type

    Returns:
        200: Success with stats (sent, skipped, errors)
        403: If user is not an admin
        500: If job execution fails

    Example:
        POST /api/user/trigger_daily_summary
        Headers: Authorization: Bearer <jwt_token>

        Response:
        {
            "result": {
                "sent": 15,
                "skipped": 5,
                "errors": 0,
                "total_users": 20
            }
        }
    """
    # Check if user is admin
    current_user = g.current_user

    # Verify user has admin privileges
    is_admin = False
    if hasattr(current_user, 'user_type') and current_user.user_type:
        is_admin = current_user.user_type.title == 'Admin'

    if not is_admin:
        return jsonify({
            'error': 'Admin access required'
        }), 403

    try:
        # Execute daily summary job
        result = send_daily_summary()

        return jsonify({
            'result': result
        }), 200

    except Exception as e:
        return jsonify({
            'error': f'Failed to execute daily summary: {str(e)}'
        }), 500
