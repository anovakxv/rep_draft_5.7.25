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
    print("Received data:", data)  # Log the raw incoming data

    if not data:
        print("No JSON received or invalid JSON.")
        return jsonify({"error": "Missing JSON body"}), 400

    device_token = data.get('device_token')
    print("Parsed device_token:", device_token)  # Log the parsed device_token

    if not device_token:
        print("device_token missing from request.")
        return jsonify({"error": "Missing device_token"}), 400

    user_id = get_jwt_identity()
    print("JWT user_id:", user_id)  # Log the user ID from JWT

    u = User.query.get(user_id)
    if not u:
        print(f"User not found for user_id={user_id}")
        return jsonify({"error": "User not found"}), 404

    u.device_token = device_token
    db.session.commit()
    print(f"Registered device_token for user_id={user_id}: {device_token}")  # Confirm update

    return jsonify({"message": "Device token updated"}), 200