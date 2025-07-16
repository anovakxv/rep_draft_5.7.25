# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify
from app import db
from app.models.People_Models.user import User
from sqlalchemy import or_

search_people_bp = Blueprint('search_people', __name__)

@search_people_bp.route('/api/search_people', methods=['GET'])
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

    # Simple search: case-insensitive match on fname, lname, or username
    search = f"%{q}%"
    users = (
        db.session.query(User)
        .filter(
            or_(
                User.fname.ilike(search),
                User.lname.ilike(search),
                User.username.ilike(search),
                (User.fname + ' ' + User.lname).ilike(search)
            )
        )
        .order_by(User.fname.asc(), User.lname.asc())
        .offset(offset)
        .limit(limit)
        .all()
    )

    return jsonify({"result": [u.as_dict() for u in users]})