# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app import db
from app.models.People_Models.Skill import Skill 
from app.utils.auth import jwt_required

user_bp = Blueprint('get_skills', __name__)

@user_bp.route('/get_skills', methods=['GET'])
@jwt_required
def api_get_skills():
    args = request.args
    offset = int(args.get('offset', 0))
    limit = int(args.get('limit', 50))
    parent_id = args.get('parent_id')
    skills_id = args.get('skills_id')
    keyword = args.get('keyword', '')

    if offset < 0:
        return jsonify({'error': 'offset is wrong!'}), 400
    if limit > 4096:
        return jsonify({'error': 'limit should be < 4096'}), 400

    query = Skill.query.filter_by(visible=True)

    if parent_id:
        query = query.filter(Skill.parent == parent_id)
    if skills_id:
        query = query.filter(Skill.id == skills_id)
    if keyword:
        query = query.filter(Skill.title.ilike(f"%{keyword.strip()}%"))

    skills = query.offset(offset).limit(limit).all()
    result = [s.as_dict() for s in skills]
    return jsonify({'result': result})