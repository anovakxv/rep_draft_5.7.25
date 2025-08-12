# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: August 2025

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.models.People_Models import user as User
from app import db

user_bp = Blueprint('device_token', __name__)

@user_bp.route('/device_token', methods=['POST'])
@jwt_required()
def register_device_token():
    data = request.get_json()
    device_token = data.get('device_token')
    if not device_token:
        return jsonify({"error": "Missing device_token"}), 400

    user_id = get_jwt_identity()
    u = User.query.get(user_id)
    if not u:
        return jsonify({"error": "User not found"}), 404

    u.device_token = device_token
    db.session.commit()
    print(f"Registered device_token for user_id={user_id}: {device_token}")  
    return jsonify({"message": "Device token updated"}), 200
