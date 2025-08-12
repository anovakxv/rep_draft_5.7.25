# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: August 2025

from flask import Blueprint, request, jsonify, g
from app import db
from app.models.People_Models.user import User
from app.utils.auth import jwt_required

user_bp = Blueprint('device_token', __name__)

@user_bp.route('/device_token', methods=['POST'])
@jwt_required
def register_device_token():
    data = request.get_json(silent=True) or {}
    print("Received data:", data)  # Log the raw incoming data

    if not data:
        print("No JSON received or invalid JSON.")
        return jsonify({"error": "Missing JSON body"}), 400

    device_token = data.get('device_token')
    print("Parsed device_token:", device_token)  # Log the parsed device_token

    if not device_token:
        print("device_token missing from request.")
        return jsonify({"error": "Missing device_token"}), 400

    if not hasattr(g, "current_user") or g.current_user is None:
        print("No authenticated user in context.")
        return jsonify({"error": "Unauthorized"}), 401

    try:
        u = User.query.get(g.current_user.id)
    except Exception as e:
        print("Error loading user from DB:", e)
        return jsonify({"error": "Server error loading user"}), 500

    if not u:
        print(f"User not found for user_id={getattr(g.current_user, 'id', None)}")
        return jsonify({"error": "User not found"}), 404

    u.device_token = device_token
    db.session.commit()
    print(f"Registered device_token for user_id={u.id}: {device_token}")  # Confirm update

    return jsonify({"message": "Device token updated"}), 200