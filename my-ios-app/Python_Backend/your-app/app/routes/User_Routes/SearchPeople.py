# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify
from app import db, limiter
from app.models.People_Models.user import User
from app.utils.auth import jwt_required
from sqlalchemy import or_

search_people_bp = Blueprint('search_people', __name__)

@search_people_bp.route('/api/search_people', methods=['GET'])
@jwt_required
@limiter.limit("60 per minute")
def search_people():
    """
    Search users by name (fname or lname or full_name or username).
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

    # Search by name only — NOT username (== email), to prevent email enumeration.
    search = f"%{q}%"
    users = (
        db.session.query(User)
        .filter(
            or_(
                User.fname.ilike(search),
                User.lname.ilike(search),
                (User.fname + ' ' + User.lname).ilike(search)
            )
        )
        .order_by(User.fname.asc(), User.lname.asc())
        .offset(offset)
        .limit(limit)
        .all()
    )

    S3_BASE_URL = "https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/"
    def safe_user(u):
        url = getattr(u, 'profile_picture_url', None)
        if url and not url.startswith("http"):
            url = S3_BASE_URL + url
        return {
            'id': u.id,
            'fname': u.fname,
            'lname': u.lname,
            # username (== email) intentionally omitted — search results must not leak emails
            'about': u.about,
            'profile_picture_url': url,
        }
    return jsonify({"result": [safe_user(u) for u in users]})