# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify
from app.utils.auth import jwt_required

user_bp = Blueprint('hide_convo', __name__)

# TODO: UsersHiddenConversations model not yet created.
# This endpoint is stubbed until the model and migration are in place.
@user_bp.route('/hide_conversation', methods=['POST'])
@jwt_required
def api_hide_conversation():
    return jsonify({'error': 'Feature not yet available'}), 501
    