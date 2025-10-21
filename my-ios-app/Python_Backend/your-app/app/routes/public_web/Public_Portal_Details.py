# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: October 2025
# PUBLIC WEB ROUTES - Read-only access for unauthenticated users

from flask import Blueprint, request, jsonify
from app import db
from app.models.Purpose_Models.Portal import Portal
from app.models.ValueMetric_Models.Goal import Goal
from app.models.Purpose_Models.PortalUser import PortalUser
from app.models.Purpose_Models.PortalTexts import PortalText
from app.models.People_Models.user import User
from app.models.Purpose_Models.PortalGraphicSection import PortalGraphicSection
from app.models.s3Content_Models.s3Content import S3Content
from sqlalchemy.orm import joinedload, subqueryload

# --- S3 BASE URL ---
S3_BASE_URL = "https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/"

public_portal_details_bp = Blueprint('public_portal_details', __name__)

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

    # Get goals for this portal
    goals = Goal.query.filter_by(portals_id=portal.id).order_by(Goal.id.desc()).all()

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
        'aGoals': [g.as_dict() for g in goals],
        'aPortalUsers': [pu.as_dict() for pu in portal_users],
        'aTexts': [t.as_dict() for t in texts],
        'aSections': aSections,
        'aUsers': [user_as_portal_dict(u) for u in all_users],
        'aLeads': [user_as_portal_dict(u) for u in lead_users],
        'lead_user_count': len(lead_user_ids),
        'user_count': len(all_user_ids),
    }

    return jsonify({'result': portal_data})
