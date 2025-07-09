# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app import db
from app.models.People_Models.user import User
from app.utils.auth import jwt_required

# --- S3 BASE URL ---
S3_BASE_URL = "https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/"

user_bp = Blueprint('get_users', __name__)

def patch_profile_picture_url(user_row):
    url = user_row.get('profile_picture_url')
    if url and not url.startswith("http"):
        user_row['profile_picture_url'] = S3_BASE_URL + url
    if not url or str(url).strip() == "":
        user_row['profile_picture_url'] = None
    return user_row

@user_bp.route('/get_users', methods=['GET'])
@jwt_required
def api_get_users():
    args = request.args
    offset = int(args.get('offset', 0))
    limit = int(args.get('limit', 50))
    users_types_id = args.get('users_types_id')
    keyword = args.get('keyword', '')
    lat = args.get('lat')
    lng = args.get('lng')
    restrict_by_distance = args.get('restrict_by_distance', '0')
    distance = float(args.get('distance', 10))
    user_id = g.current_user.id

    if offset < 0:
        return jsonify({'error': 'offset is wrong!'}), 400
    if limit > 4096:
        return jsonify({'error': 'limit should be <= 4096'}), 400

    query = User.query

    if users_types_id:
        query = query.filter(User.users_types_id == users_types_id)

    if keyword:
        keyword = keyword.strip().lower()
        query = query.filter(
            (User.fname + ' ' + User.lname).ilike(f"%{keyword}%")
        )

    if lat and lng:
        try:
            lat = float(lat)
            lng = float(lng)
            if restrict_by_distance == '1':
                if distance < 1:
                    return jsonify({'error': 'distance < 1'}), 400
                # Haversine formula for miles (raw SQL for filtering)
                query = query.filter(
                    db.text(
                        f"((ACOS( SIN(lat * PI() /180 ) * SIN({lat} * PI()/180 ) + COS(lat * PI()/180 ) * COS({lat} * PI()/180 ) * COS( ((lng+0.000001) - ({lng}) ) * PI()/180 ) ) *180 / PI() ) * 60 * 1.1515) <= {distance}"
                    )
                )
            query = query.filter(User.lat != 0, User.lng != 0)
        except Exception:
            return jsonify({'error': 'Invalid latitude or longitude'}), 400

    if user_id:
        query = query.filter(User.id != user_id)

    users = query.order_by(User.id.desc()).offset(offset).limit(limit).all()
    result = []
    for u in users:
        user_row = u.as_dict()
        user_row = patch_profile_picture_url(user_row)
        result.append(user_row)
    return jsonify({'result': result})