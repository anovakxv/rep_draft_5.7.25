# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
#
# Rep Coach API. The conversation lives in the member's browser for now (no database
# table), so each request carries the recent turns and the server stays stateless.
#
# Env vars:
#   ANTHROPIC_API_KEY   required
#   COACH_ENABLED       "true" to turn Coach on (anything else = off, and the app hides it)
#   COACH_MODEL         optional, default claude-sonnet-5-5
#   COACH_DAILY_LIMIT   optional, default "40 per day" (per member)

import logging
import os

from flask import Blueprint, g, jsonify, request

from app import limiter
from app.utils import rep_coach
from app.utils.auth import jwt_required

logger = logging.getLogger(__name__)

coach_bp = Blueprint('coach', __name__)

MAX_TURNS = 12          # only the most recent turns are sent to Claude
MAX_USER_CHARS = 2000
MAX_ASSISTANT_CHARS = 4000


def _member_key():
    return f"coach-member-{g.current_user.id}"


def _daily_limit():
    return os.getenv("COACH_DAILY_LIMIT", "40 per day")


# GET /api/coach/status -> {"enabled": bool}; the app only shows Coach when it's on
@coach_bp.route('/status', methods=['GET'])
@jwt_required
def coach_status():
    return jsonify({"enabled": rep_coach.coach_enabled()})


# POST /api/coach/message  {"messages": [{"role": "user"|"assistant", "text": "..."}, ...]}
# -> {"reply": "...", "cards": {"purpose:12": {...}, ...}}
@coach_bp.route('/message', methods=['POST'])
@jwt_required
@limiter.limit(_daily_limit, key_func=_member_key)
@limiter.limit("6 per minute", key_func=_member_key)
def coach_message():
    if not rep_coach.coach_enabled():
        return jsonify({"error": "Rep Coach is turned off right now."}), 503

    data = request.get_json(silent=True) or {}
    raw = data.get("messages")
    if not isinstance(raw, list) or not raw:
        return jsonify({"error": "messages is required"}), 400

    history = []
    for m in raw[-MAX_TURNS:]:
        if not isinstance(m, dict):
            return jsonify({"error": "Each message needs a role and text"}), 400
        role, text = m.get("role"), m.get("text")
        if role not in ("user", "assistant") or not isinstance(text, str) or not text.strip():
            return jsonify({"error": "Each message needs a role (user or assistant) and text"}), 400
        text = text.strip()
        if role == "user" and len(text) > MAX_USER_CHARS:
            return jsonify({"error": f"Please keep messages under {MAX_USER_CHARS} characters."}), 400
        history.append({"role": role, "text": text[:MAX_ASSISTANT_CHARS]})

    if history[-1]["role"] != "user":
        return jsonify({"error": "The last message must be from the member"}), 400

    try:
        result = rep_coach.reply(g.current_user, history)
    except Exception:
        logger.exception("Rep Coach failed for user %s", g.current_user.id)
        return jsonify({"error": "Rep Coach is having trouble right now. Try again in a minute."}), 502
    return jsonify(result)
