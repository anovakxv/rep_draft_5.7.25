# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify
from app import db
from app.models.Purpose_Models.Portal import Portal
from sqlalchemy import or_

search_portals_bp = Blueprint('search_portals', __name__)

@search_portals_bp.route('/api/search_portals', methods=['GET'])
def search_portals():
    """
    Search portals by name or subtitle.
    Query params:
        q: search string (required)
        limit: max results (default 50)
        offset: for pagination (default 0)
    """
    q = request.args.get('q', '', type=str).strip()
    limit = request.args.get('limit', 50, type=int)
    offset = request.args.get('offset', 0, type=int)

    if not q:
        return jsonify({"result": [], "error": "Missing search query"}), 400

    search = f"%{q}%"
    portals = (
        db.session.query(Portal)
        .filter(
            Portal.visible == True,
            or_(
                Portal.name.ilike(search),
                Portal.subtitle.ilike(search)
            )
        )
        .order_by(Portal.name.asc())
        .offset(offset)
        .limit(limit)
        .all()
    )

    return jsonify({"result": [p.as_card_dict() for p in portals]})