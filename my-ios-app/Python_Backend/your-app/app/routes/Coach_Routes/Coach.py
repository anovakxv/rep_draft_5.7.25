# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
#
# Rep Coach + Rep Onboarding API. Conversations are saved (coach_messages) and the server
# owns the history: the app sends only the member's new message. Members can delete one
# message or all of them (permanently), and view, edit or clear what Coach knows
# (coach_memories). Older app versions that send the whole conversation still work.
#
# Env vars:
#   ANTHROPIC_API_KEY             required
#   COACH_ENABLED                 "true" to turn Coach on (anything else = off, and the app hides it)
#   COACH_MODEL                   optional, default claude-sonnet-5-5
#   COACH_DAILY_LIMIT             optional, default "40 per day" (per member)
#   ONBOARDING_DAILY_LIMIT        optional, default "60 per day" (per member)
#   COACH_PROMPTS_FILE            optional prompts file (see app/utils/coach_prompts.py)

import logging
import os

from flask import Blueprint, g, jsonify, request

from app import db, limiter
from app.models.Coach_Models import CoachMemory, CoachMessage
from app.models.Coach_Models.CoachMessage import THREADS
from app.utils import coach_store, rep_coach, rep_onboarding
from app.utils.auth import jwt_required

logger = logging.getLogger(__name__)

coach_bp = Blueprint('coach', __name__)

MAX_TURNS = 12              # Coach: recent turns sent to Claude
MAX_ONBOARDING_TURNS = 30   # Onboarding: the whole interview usually fits
MAX_USER_CHARS = 2000
MAX_ASSISTANT_CHARS = 4000
PAGE_LIMIT = 50

OFF_ERROR = ({"error": "Rep Coach is turned off right now."}, 503)
TROUBLE_ERROR = ({"error": "Rep Coach is having trouble right now. Try again in a minute."}, 502)


def _member_key():
    return f"coach-member-{g.current_user.id}"


def _onboarding_key():
    return f"onboarding-member-{g.current_user.id}"


def _daily_limit():
    return os.getenv("COACH_DAILY_LIMIT", "40 per day")


def _onboarding_limit():
    return os.getenv("ONBOARDING_DAILY_LIMIT", "60 per day")


def _memory_row(member_id):
    """The member's memory row, committed first if it's new, so a rollback during a reply
    (e.g. a failed search) can't discard it."""
    memory = CoachMemory.for_user(member_id)
    if memory.id is None:
        db.session.commit()
    return memory


def _member_text(data):
    """The member's new message from a request body, or (None, error response)."""
    text = data.get("text")
    if not isinstance(text, str) or not text.strip():
        return None, (jsonify({"error": "text is required"}), 400)
    text = text.strip()
    if len(text) > MAX_USER_CHARS:
        return None, (jsonify({"error": f"Please keep messages under {MAX_USER_CHARS} characters."}), 400)
    return text, None


# --- Status ---------------------------------------------------------------

# GET /api/coach/status -> {"enabled": bool, "onboarding_status": str}
@coach_bp.route('/status', methods=['GET'])
@jwt_required
def coach_status():
    memory = coach_store.get_memory(g.current_user.id)
    return jsonify({
        "enabled": rep_coach.coach_enabled(),
        "onboarding_status": memory.onboarding_status if memory else "not_started",
    })


# --- Rep Coach --------------------------------------------------------------

# POST /api/coach/message
#   {"text": "..."}  -> saved conversation (current app):
#       {"reply", "cards", "user_message": {...}, "message": {...}}
#   {"messages": [{"role", "text"}, ...]}  -> older app versions (nothing saved):
#       {"reply", "cards"}
@coach_bp.route('/message', methods=['POST'])
@jwt_required
@limiter.limit(_daily_limit, key_func=_member_key)
@limiter.limit("6 per minute", key_func=_member_key)
def coach_message():
    if not rep_coach.coach_enabled():
        return jsonify(OFF_ERROR[0]), OFF_ERROR[1]

    data = request.get_json(silent=True) or {}
    if "text" not in data and isinstance(data.get("messages"), list):
        return _legacy_message(data["messages"])

    text, error = _member_text(data)
    if error:
        return error

    member = g.current_user
    try:
        memory = _memory_row(member.id)
        history = coach_store.recent_turns(member.id, "coach", MAX_TURNS - 1)
        history.append({"role": "user", "text": text})
        result = rep_coach.reply(member, history, memory=memory)

        user_msg = coach_store.add_turn(member.id, "coach", "user", text)
        bot_msg = coach_store.add_turn(
            member.id, "coach", "assistant", result["reply"],
            payload={"cards": result["cards"]} if result["cards"] else None,
            model=result["model"], usage=result["usage"],
        )
        db.session.commit()
    except Exception:
        db.session.rollback()
        logger.exception("Rep Coach failed for user %s", member.id)
        return jsonify(TROUBLE_ERROR[0]), TROUBLE_ERROR[1]

    return jsonify({
        "reply": result["reply"],
        "cards": result["cards"],
        "user_message": user_msg.as_dict(),
        "message": bot_msg.as_dict(),
    })


def _legacy_message(raw):
    """Older app versions send the recent turns; answer without saving anything."""
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

    if not history or history[-1]["role"] != "user":
        return jsonify({"error": "The last message must be from the member"}), 400

    try:
        result = rep_coach.reply(g.current_user, history)
    except Exception:
        logger.exception("Rep Coach failed for user %s", g.current_user.id)
        return jsonify(TROUBLE_ERROR[0]), TROUBLE_ERROR[1]
    return jsonify({"reply": result["reply"], "cards": result["cards"]})


# --- Saved conversations (both threads) -----------------------------------

# GET /api/coach/messages?thread=coach|onboarding&before_id=123&limit=50
#   -> {"messages": [...oldest first], "has_more": bool}
@coach_bp.route('/messages', methods=['GET'])
@jwt_required
def list_messages():
    thread = request.args.get("thread", "coach")
    if thread not in THREADS:
        return jsonify({"error": "thread must be coach or onboarding"}), 400
    before_id = request.args.get("before_id", type=int)
    limit = max(1, min(request.args.get("limit", PAGE_LIMIT, type=int) or PAGE_LIMIT, 100))
    messages, has_more = coach_store.page(g.current_user.id, thread, before_id, limit)
    return jsonify({"messages": messages, "has_more": has_more})


# DELETE /api/coach/messages/<id>  -> permanently delete one of your messages
@coach_bp.route('/messages/<int:message_id>', methods=['DELETE'])
@jwt_required
def delete_message(message_id):
    msg = CoachMessage.query.filter_by(id=message_id, user_id=g.current_user.id).first()
    if msg is None:
        return jsonify({"error": "Message not found"}), 404
    db.session.delete(msg)
    db.session.commit()
    return jsonify({"deleted": 1})


# DELETE /api/coach/messages?thread=coach|onboarding|all&clear_memory=true
#   -> permanently delete a whole thread (or both); optionally also forget what Coach knows
@coach_bp.route('/messages', methods=['DELETE'])
@jwt_required
def delete_messages():
    thread = request.args.get("thread", "all")
    if thread != "all" and thread not in THREADS:
        return jsonify({"error": "thread must be coach, onboarding or all"}), 400
    member_id = g.current_user.id
    deleted = coach_store.delete_turns(member_id, None if thread == "all" else thread)
    cleared = False
    if request.args.get("clear_memory", "").lower() == "true":
        memory = coach_store.get_memory(member_id)
        if memory is not None:
            coach_store.clear_memory(memory)
            cleared = True
    db.session.commit()
    return jsonify({"deleted": deleted, "memory_cleared": cleared})


# --- What Coach knows -------------------------------------------------------

# GET /api/coach/memory -> {"narrative", "facts", "onboarding", "write_saved_at", "updated_at"}
@coach_bp.route('/memory', methods=['GET'])
@jwt_required
def get_memory():
    memory = coach_store.get_memory(g.current_user.id)
    if memory is None:
        return jsonify({"narrative": None, "facts": {}, "onboarding": coach_store.onboarding_state(None),
                        "write_saved_at": None, "updated_at": None})
    return jsonify(memory.as_dict())


# PUT /api/coach/memory {"narrative"?: str|null, "facts"?: {...}}  -> the member edits what Coach knows
# facts replaces the whole set (send everything you want kept).
@coach_bp.route('/memory', methods=['PUT'])
@jwt_required
def update_memory():
    data = request.get_json(silent=True) or {}
    if "narrative" not in data and "facts" not in data:
        return jsonify({"error": "Send narrative and/or facts"}), 400
    narrative = data.get("narrative")
    if "narrative" in data and narrative is not None and not isinstance(narrative, str):
        return jsonify({"error": "narrative must be text"}), 400
    if "facts" in data and not isinstance(data.get("facts"), dict):
        return jsonify({"error": "facts must be an object"}), 400

    memory = CoachMemory.for_user(g.current_user.id)
    if "narrative" in data:
        memory.narrative = (narrative or "").strip()[:coach_store.MAX_NARRATIVE_CHARS] or None
    if "facts" in data:
        memory.facts = coach_store.clean_facts(data["facts"])
    db.session.commit()
    return jsonify(memory.as_dict())


# DELETE /api/coach/memory  -> forget what Coach knows (keeps onboarding progress)
@coach_bp.route('/memory', methods=['DELETE'])
@jwt_required
def clear_memory():
    memory = coach_store.get_memory(g.current_user.id)
    if memory is not None:
        coach_store.clear_memory(memory)
        db.session.commit()
    return jsonify({"memory_cleared": memory is not None})


# --- Rep Onboarding --------------------------------------------------------

# GET /api/coach/onboarding -> {"status", "step", "steps", "answers", "completed_at"}
@coach_bp.route('/onboarding', methods=['GET'])
@jwt_required
def onboarding_status():
    return jsonify(coach_store.onboarding_state(coach_store.get_memory(g.current_user.id)))


# POST /api/coach/onboarding/start -> {"messages": [...], "onboarding": {...}}
# Opens the interview with its first question (no model call). Safe to call again: returns
# the thread as it is.
@coach_bp.route('/onboarding/start', methods=['POST'])
@jwt_required
@limiter.limit("20 per day", key_func=_onboarding_key)
def onboarding_start():
    if not rep_coach.coach_enabled():
        return jsonify(OFF_ERROR[0]), OFF_ERROR[1]
    member_id = g.current_user.id
    memory = CoachMemory.for_user(member_id)
    if not coach_store.has_turns(member_id, "onboarding"):
        coach_store.add_turn(member_id, "onboarding", "assistant", rep_onboarding.opening_text())
        if memory.onboarding_status == "not_started":
            memory.onboarding_status = "in_progress"
    db.session.commit()
    messages, _ = coach_store.page(member_id, "onboarding", limit=100)
    return jsonify({"messages": messages, "onboarding": coach_store.onboarding_state(memory)})


# POST /api/coach/onboarding/message {"text": "..."}
#   -> {"messages": [new turns...], "onboarding": {...}}
# The new turns are the member's message, the reply, and (when proposed) the Write draft card.
@coach_bp.route('/onboarding/message', methods=['POST'])
@jwt_required
@limiter.limit(_onboarding_limit, key_func=_onboarding_key)
@limiter.limit("10 per minute", key_func=_onboarding_key)
def onboarding_message():
    if not rep_coach.coach_enabled():
        return jsonify(OFF_ERROR[0]), OFF_ERROR[1]
    text, error = _member_text(request.get_json(silent=True) or {})
    if error:
        return error

    member = g.current_user
    memory = _memory_row(member.id)
    if memory.onboarding_status == "complete":
        return jsonify({"error": "Your profile is already set up. Rep Coach can help you refine it.",
                        "onboarding": coach_store.onboarding_state(memory)}), 409

    try:
        if not coach_store.has_turns(member.id, "onboarding"):
            coach_store.add_turn(member.id, "onboarding", "assistant", rep_onboarding.opening_text())
            db.session.flush()
        history = coach_store.recent_turns(member.id, "onboarding", MAX_ONBOARDING_TURNS - 1)
        history.append({"role": "user", "text": text})
        result = rep_onboarding.reply(member, memory, history)

        new_turns = [coach_store.add_turn(member.id, "onboarding", "user", text)]
        new_turns.append(coach_store.add_turn(
            member.id, "onboarding", "assistant", result["reply"],
            model=result["model"], usage=result["usage"],
        ))
        if result["draft"]:
            new_turns.append(coach_store.add_turn(
                member.id, "onboarding", "assistant", _draft_text(result["draft"]),
                kind="write_draft", payload=result["draft"],
            ))
        db.session.commit()
    except Exception:
        db.session.rollback()
        logger.exception("Rep Onboarding failed for user %s", member.id)
        return jsonify(TROUBLE_ERROR[0]), TROUBLE_ERROR[1]

    return jsonify({"messages": [m.as_dict() for m in new_turns],
                    "onboarding": coach_store.onboarding_state(memory)})


def _draft_text(draft):
    """Plain-text version of the Write draft card (what the model sees in later turns)."""
    parts = ["Draft of your Write section:"]
    for entry in draft["write_draft"]["entries"]:
        parts.append(f"{entry['title']}\n{entry['content']}")
    return "\n\n".join(parts)


# POST /api/coach/onboarding/write-draft/<message_id>
#   {"status": "saved", "entries": {"accomplish": "...", "looking_for": "...", "holding_back": "..."}}
#   {"status": "discarded"}
# The app calls this after the member saves the draft to their profile (through the regular
# Write endpoints) or discards it. Saving finishes onboarding and fills in what Coach knows.
@coach_bp.route('/onboarding/write-draft/<int:message_id>', methods=['POST'])
@jwt_required
def onboarding_write_draft(message_id):
    data = request.get_json(silent=True) or {}
    status = data.get("status")
    if status not in ("saved", "discarded"):
        return jsonify({"error": "status must be saved or discarded"}), 400

    member = g.current_user
    msg = CoachMessage.query.filter_by(id=message_id, user_id=member.id, kind="write_draft").first()
    if msg is None:
        return jsonify({"error": "Draft not found"}), 404

    payload = dict(msg.payload or {})
    payload["status"] = status
    msg.payload = payload
    memory = CoachMemory.for_user(member.id)

    if status == "saved":
        raw = data.get("entries") if isinstance(data.get("entries"), dict) else {}
        entries = {
            key: raw[key].strip()[:rep_onboarding.MAX_DRAFT_CHARS]
            for key in coach_store.PILLARS
            if isinstance(raw.get(key), str) and raw[key].strip()
        }
        # With Coach off, onboarding still completes; only the AI-written summary is skipped
        rep_onboarding.complete(member, memory, entries, summarize=rep_coach.coach_enabled())

    try:
        db.session.commit()
    except Exception:
        db.session.rollback()
        logger.exception("Saving Write draft state failed for user %s", member.id)
        return jsonify({"error": "Couldn't update the draft. Try again."}), 500
    return jsonify({"message": msg.as_dict(), "onboarding": coach_store.onboarding_state(memory)})


# POST /api/coach/onboarding/restart -> start the interview over (deletes the onboarding
# thread and its answers; keeps what Coach knows and anything saved to the profile)
@coach_bp.route('/onboarding/restart', methods=['POST'])
@jwt_required
@limiter.limit("10 per day", key_func=_onboarding_key)
def onboarding_restart():
    member_id = g.current_user.id
    coach_store.delete_turns(member_id, "onboarding")
    memory = CoachMemory.for_user(member_id)
    memory.onboarding_status = "not_started"
    memory.onboarding_step = 0
    memory.onboarding_answers = {}
    memory.onboarding_completed_at = None
    db.session.commit()
    return jsonify({"onboarding": coach_store.onboarding_state(memory)})
