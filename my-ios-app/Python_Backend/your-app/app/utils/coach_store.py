# Rep
# Copyright (c) 2026 Networked Capital Inc. All rights reserved.
#
# Storage helpers for Rep Coach / Rep Onboarding: conversation history (coach_messages)
# and what Coach knows about a member (coach_memories). AI data only; the member's own
# content (writes, DMs, group chats) is never read or changed here.

from datetime import datetime

from app import db
from app.models.Coach_Models import CoachMemory, CoachMessage

# Structured memory: text fields and list fields, with size caps
FACT_TEXT_KEYS = ("accomplish", "looking_for", "holding_back", "location")
FACT_LIST_KEYS = ("skills", "interests")
MAX_FACT_CHARS = 600
MAX_LIST_ITEMS = 20
MAX_LIST_ITEM_CHARS = 60
MAX_NARRATIVE_CHARS = 2000

# The three Write-section pillars, in order, with the titles saved on the member's profile
PILLARS = ("accomplish", "looking_for", "holding_back")
PILLAR_TITLES = {
    "accomplish": "What I'm trying to accomplish",
    "looking_for": "What I'm looking for",
    "holding_back": "What's holding me back",
}


def now_iso():
    return datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")


# --- Facts ---

def clean_facts(raw):
    """Keep only known fact keys, trimmed to size. Returns a new dict."""
    out = {}
    if not isinstance(raw, dict):
        return out
    for key in FACT_TEXT_KEYS:
        value = raw.get(key)
        if isinstance(value, str) and value.strip():
            out[key] = value.strip()[:MAX_FACT_CHARS]
    for key in FACT_LIST_KEYS:
        value = raw.get(key)
        if isinstance(value, list):
            items = []
            for item in value:
                if isinstance(item, str) and item.strip() and item.strip() not in items:
                    items.append(item.strip()[:MAX_LIST_ITEM_CHARS])
            if items:
                out[key] = items[:MAX_LIST_ITEMS]
    return out


def merge_facts(memory, raw):
    """Merge cleaned facts into memory.facts (new values replace old; lists are replaced)."""
    updates = clean_facts(raw)
    if updates:
        memory.facts = {**(memory.facts or {}), **updates}  # reassign so SQLAlchemy sees the change
    return updates


def memory_block(memory):
    """What Coach knows, as a block for the model's context (None when there's nothing yet)."""
    if memory is None:
        return None
    facts = memory.facts or {}
    lines = []
    if memory.narrative:
        lines.append(f"Summary: {memory.narrative}")
    labels = {
        "accomplish": "Trying to accomplish",
        "looking_for": "Looking for",
        "holding_back": "Holding them back",
        "location": "Location",
    }
    for key, label in labels.items():
        if facts.get(key):
            lines.append(f"{label}: {facts[key]}")
    if facts.get("skills"):
        lines.append(f"Skills: {', '.join(facts['skills'])}")
    if facts.get("interests"):
        lines.append(f"Interests: {', '.join(facts['interests'])}")
    if not lines:
        return None
    return "<member_memory>\n" + "\n".join(lines) + "\n</member_memory>"


# --- Conversation history ---

def recent_turns(user_id, thread, limit):
    """The latest `limit` turns of a thread, oldest first, as [{"role", "text"}]."""
    rows = (
        CoachMessage.query.filter_by(user_id=user_id, thread=thread)
        .order_by(CoachMessage.created_at.desc(), CoachMessage.id.desc())
        .limit(limit)
        .all()
    )
    return [{"role": m.role, "text": m.text} for m in reversed(rows)]


def page(user_id, thread, before_id=None, limit=50):
    """A page of a thread for the app, oldest first, plus whether older turns exist."""
    q = CoachMessage.query.filter_by(user_id=user_id, thread=thread)
    if before_id:
        q = q.filter(CoachMessage.id < before_id)
    rows = q.order_by(CoachMessage.id.desc()).limit(limit + 1).all()
    has_more = len(rows) > limit
    return [m.as_dict() for m in reversed(rows[:limit])], has_more


def add_turn(user_id, thread, role, text, kind="text", payload=None, model=None, usage=None):
    """Stage one turn (the caller commits)."""
    msg = CoachMessage(
        user_id=user_id,
        thread=thread,
        role=role,
        kind=kind,
        text=text,
        payload=payload,
        model=model,
        input_tokens=(usage or {}).get("input"),
        output_tokens=(usage or {}).get("output"),
    )
    db.session.add(msg)
    return msg


def has_turns(user_id, thread):
    return db.session.query(CoachMessage.id).filter_by(user_id=user_id, thread=thread).first() is not None


def delete_turns(user_id, thread=None):
    """Permanently delete a member's turns (one thread, or all). Returns how many."""
    q = CoachMessage.query.filter_by(user_id=user_id)
    if thread:
        q = q.filter_by(thread=thread)
    return q.delete(synchronize_session=False)


# --- Memory ---

def get_memory(user_id):
    """The member's memory row, or None (doesn't create one)."""
    return CoachMemory.query.filter_by(user_id=user_id).first()


def clear_memory(memory):
    """Forget what Coach knows (keeps onboarding progress: the profile is still done)."""
    memory.narrative = None
    memory.facts = {}


def onboarding_state(memory):
    if memory is None:
        return {"status": "not_started", "step": 0, "answers": {}, "completed_at": None}
    return memory.as_dict()["onboarding"]
