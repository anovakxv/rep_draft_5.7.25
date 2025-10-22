# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: October 2025
# PUBLIC WEB ROUTES - Read-only access for unauthenticated users

from flask import Blueprint, request, jsonify
from app import db
from app.models.Purpose_Models.Portal import Portal
from app.models.ValueMetric_Models.Goal import Goal
from app.models.ValueMetric_Models.GoalProgressLog import GoalProgressLog
from app.models.Purpose_Models.PortalUser import PortalUser
from app.models.Purpose_Models.PortalTexts import PortalText
from app.models.People_Models.user import User
from app.models.Purpose_Models.PortalGraphicSection import PortalGraphicSection
from app.models.s3Content_Models.s3Content import S3Content
from sqlalchemy.orm import joinedload, subqueryload
from collections import OrderedDict

# --- S3 BASE URL ---
S3_BASE_URL = "https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/"

public_portal_details_bp = Blueprint('public_portal_details', __name__)

def get_increment(goal):
    """Determine time increment from goal's reporting increment"""
    increment = "month"
    if hasattr(goal, "reporting_increment") and goal.reporting_increment and hasattr(goal.reporting_increment, "title"):
        title = goal.reporting_increment.title.lower().strip()
        if title == "daily" or "day" in title:
            increment = "day"
        elif title == "weekly" or "week" in title:
            increment = "week"
        elif title == "monthly" or "month" in title:
            increment = "month"
    return increment

def patched_chart_data(goal, increment='day', num_periods=4):
    """
    Generate chart data grouped by time increment with cumulative values.
    This matches the logic in GetGoals.py for the authenticated endpoint.
    """
    logs = goal.progress_logs.order_by(GoalProgressLog.timestamp.asc()).all()
    cumulative = 0
    data = OrderedDict()

    for log in logs:
        if log.timestamp:
            if increment == 'month':
                label = log.timestamp.strftime('%Y-%m')
                display_label = log.timestamp.strftime('%b')
            elif increment == 'week':
                label = f"{log.timestamp.year}-W{log.timestamp.isocalendar()[1]}"
                display_label = f"W{log.timestamp.isocalendar()[1]}"
            elif increment == 'day':
                label = log.timestamp.strftime('%Y-%m-%d')
                display_label = log.timestamp.strftime('%d %b')
            else:
                label = log.timestamp.strftime('%Y-%m')
                display_label = log.timestamp.strftime('%b')

            cumulative += float(log.added_value or 0)
            data[label] = (cumulative, display_label)

    # Only keep the last num_periods periods
    items = list(data.items())[-num_periods:]
    chart_data = [
        {
            "id": idx + 1,
            "value": value,
            "valueLabel": str(value),
            "bottomLabel": display_label
        }
        for idx, (label, (value, display_label)) in enumerate(items)
    ]
    return chart_data

def user_as_portal_dict(user):
    """Helper to serialize user data for portal details"""
    url = getattr(user, "profile_picture_url", None)
    if url and not url.startswith("http"):
        url = S3_BASE_URL + url
    if not url or str(url).strip() == "":
        url = None
    return {
        "id": user.id,
        "fname": user.fname,
        "lname": user.lname,
        "username": getattr(user, "username", None),
        "profile_picture_url": url,
    }

@public_portal_details_bp.route('/portal/<int:portal_id>', methods=['GET'])
def api_public_portal_details(portal_id):
    """
    PUBLIC API: Returns detailed information for a single portal (no authentication required).
    Used for public web app PortalPage.

    Path params:
    - portal_id: ID of the portal to fetch
    """
    if not portal_id:
        return jsonify({'error': 'portal_id required'}), 400

    # Fetch portal with all related data
    portal = Portal.query.options(
        joinedload(Portal.creator),
        joinedload(Portal.lead),
        joinedload(Portal.category),
        joinedload(Portal.city),
        subqueryload(Portal.portal_users),
        subqueryload(Portal.portal_texts),
        subqueryload(Portal.graphic_sections)
    ).filter_by(id=portal_id).first()

    if not portal:
        return jsonify({'error': "Portal not found"}), 404

    # Only show visible portals to public
    if not portal.visible:
        return jsonify({'error': "Portal not found"}), 404

    # Batch fetch S3 files for all graphic sections
    sections = portal.graphic_sections
    section_ids = [section.id for section in sections]
    files_by_section = {}

    if section_ids:
        files = S3Content.query.filter(
            S3Content.tbl_index == 6,
            S3Content.tbl_id.in_(section_ids)
        ).all()

        for f in files:
            file_url = f.url
            if file_url and not file_url.startswith("http"):
                file_url = S3_BASE_URL + file_url
            files_by_section.setdefault(f.tbl_id, []).append({
                'id': f.id,
                'gr_hash': f.gr_hash,
                'key': f.key,
                'url': file_url
            })

    # Compose graphic sections with files
    aSections = []
    for section in sections:
        aSections.append({
            'id': section.id,
            'title': section.title,
            'aFiles': files_by_section.get(section.id, [])
        })

    # Get all portal users and leads
    portal_users = portal.portal_users
    all_user_ids = set([portal.users_id] + [pu.user_id for pu in portal_users])
    all_users = User.query.filter(User.id.in_(all_user_ids)).all()

    # Get only leads
    portal_leads = [pu for pu in portal_users if pu.role == 'lead']
    lead_user_ids = set([portal.users_id] + [pu.user_id for pu in portal_leads])
    lead_users = User.query.filter(User.id.in_(lead_user_ids)).all()

    # Get goals for this portal with proper chart data
    goals = Goal.query.options(joinedload(Goal.reporting_increment)).filter_by(portals_id=portal.id).order_by(Goal.id.desc()).all()

    # Build goals array with properly formatted chart data (matching authenticated endpoint)
    aGoals = []
    for goal in goals:
        increment = get_increment(goal)
        chart_data = patched_chart_data(goal, increment=increment, num_periods=4)

        result = goal.as_dict(increment=increment, num_periods=4)
        result["chartData"] = chart_data
        aGoals.append(result)

    # Get portal texts
    texts = portal.portal_texts

    # Get main image URL
    main_image_url = portal.main_image_url
    if main_image_url and not main_image_url.startswith("http"):
        main_image_url = S3_BASE_URL + main_image_url

    # Compose portal data
    portal_data = {
        'id': portal.id,
        'name': portal.name,
        'subtitle': portal.subtitle,
        'about': portal.about,
        'categories_id': portal.categories_id,
        'cities_id': portal.cities_id,
        'lead_id': portal.lead_id,
        'users_id': portal.users_id,
        '_c_users_count': getattr(portal, '_c_users_count', None),
        'mainImageUrl': main_image_url,
        'aGoals': aGoals,
        'aPortalUsers': [pu.as_dict() for pu in portal_users],
        'aTexts': [t.as_dict() for t in texts],
        'aSections': aSections,
        'aUsers': [user_as_portal_dict(u) for u in all_users],
        'aLeads': [user_as_portal_dict(u) for u in lead_users],
        'lead_user_count': len(lead_user_ids),
        'user_count': len(all_user_ids),
    }

    return jsonify({'result': portal_data})
