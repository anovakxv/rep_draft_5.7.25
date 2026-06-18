# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, jsonify
from app.utils.auth import jwt_required

user_bp = Blueprint('hide_chat_convo', __name__)

# TODO: ChatsHiddenConversations model not yet created.
# This endpoint is stubbed until the model and migration are in place.
# (Previously referenced an unimported model and crashed with NameError on every call.)
@user_bp.route('/hide_chat_conversation', methods=['POST'])
@jwt_required
def api_hide_chat_conversation():
    return jsonify({'error': 'Feature not yet available'}), 501
