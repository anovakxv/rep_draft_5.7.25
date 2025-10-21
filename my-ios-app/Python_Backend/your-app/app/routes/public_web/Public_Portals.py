# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: October 2025
# PUBLIC WEB ROUTES - Read-only access for unauthenticated users

from flask import Blueprint, request, jsonify
from app import db
from app.models.Purpose_Models.Portal import Portal
from app.models.Purpose_Models.FlaggedPortal import FlaggedPortal
from sqlalchemy.orm import subqueryload

# --- S3 BASE URL ---
S3_BASE_URL = "https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/"

def patch_main_image_url(portal_dict):
    """
    Ensures mainImageUrl is a full S3 URL or None.
    """
    url = portal_dict.get('mainImageUrl')
    if url and not url.startswith("http"):
        portal_dict['mainImageUrl'] = S3_BASE_URL + url
    if not url or str(url).strip() == "":
        portal_dict['mainImageUrl'] = None
    return portal_dict

public_portals_bp = Blueprint('public_portals', __name__)

@public_portals_bp.route('/portals', methods=['GET'])
def api_public_get_portals():
    """
    PUBLIC API: Returns a list of all visible portals (no authentication required).
    Used for public web app MainScreen "All" tab.

    Query params:
    - offset: pagination offset (default: 0)
    - limit: max results (default: 50, max: 200)
    - keyword: search by portal name
    - safe_only: filter out flagged portals (default: true)
    """
    args = request.args
    offset = int(args.get('offset', 0))
    limit = int(args.get('limit', 50))
    keyword = args.get('keyword', '')
    safe_only = args.get('safe_only', 'true').lower() == 'true'

    if offset < 0:
        return jsonify({'error': 'offset must be >= 0'}), 400
    if limit > 200:
        return jsonify({'error': 'limit must be <= 200'}), 400

    # Start with all visible portals
    query = Portal.query.options(
        subqueryload(Portal.graphic_sections)
    ).filter(Portal.visible == True)

    # Filter out flagged portals by default (safe mode)
    if safe_only:
        flagged_portal_ids = db.session.query(FlaggedPortal.portal_id).distinct()
        query = query.filter(~Portal.id.in_(flagged_portal_ids))

    # Keyword search
    if keyword:
        query = query.filter(Portal.name.ilike(f"%{keyword.lower()}%"))

    # Order by popularity (lead_user_count) and paginate
    query = query.order_by(Portal.lead_user_count.desc())
    portals = query.offset(offset).limit(limit).all()

    # Return portal cards with full S3 URLs
    result = [patch_main_image_url(portal.as_card_dict()) for portal in portals]
    return jsonify({'result': result})
