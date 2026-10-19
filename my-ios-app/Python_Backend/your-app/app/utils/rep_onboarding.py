# Rep
# Copyright (c) 2026 Networked Capital Inc. All rights reserved.
#
# Rep Onboarding: a guided interview that helps a new member write their Rep profile.
# It records the member's answers on the three Write-section pillars (plus a few details),
# then proposes a Write section draft for the member to review. It never saves anything to
# the member's profile: the member saves the draft themselves from the app.
#
# Prompt text comes from app/utils/coach_prompts.py.

import json
import logging
from datetime import datetime

from app.utils import coach_store
from app.utils.coach_prompts import prompt
from app.utils.rep_coach import ToolError, build_messages, converse, profile_block

logger = logging.getLogger(__name__)

MAX_PILLAR_SUMMARY = 600
MAX_DRAFT_CHARS = 2500

TOOLS = [
    {
        "name": "record_pillar",
        "description": "Record the member's answer for one Write-section pillar, as a short summary in their own terms.",
        "input_schema": {
            "type": "object",
            "properties": {
                "pillar": {"type": "string", "enum": list(coach_store.PILLARS)},
                "summary": {"type": "string", "description": "What the member said, summarized."},
                "quality": {"type": "string", "enum": ["strong", "light"]},
            },
            "required": ["pillar", "summary", "quality"],
        },
    },
    {
        "name": "record_details",
        "description": "Record the member's location and a few skills or interests.",
        "input_schema": {
            "type": "object",
            "properties": {
                "location": {"type": "string"},
                "skills": {"type": "array", "items": {"type": "string"}},
                "interests": {"type": "array", "items": {"type": "string"}},
            },
        },
    },
    {
        "name": "propose_write_draft",
        "description": "Propose the member's Write section (one entry per pillar) for them to review, edit and save. Only after all three pillars are recorded.",
        "input_schema": {
            "type": "object",
            "properties": {key: {"type": "string"} for key in coach_store.PILLARS},
            "required": list(coach_store.PILLARS),
        },
    },
]


def _state_block(memory):
    """Where the interview stands, for the model's context."""
    answers = memory.onboarding_answers or {}
    lines = [f"Step: {memory.onboarding_step} of 4 ({memory.onboarding_status})"]
    for key in coach_store.PILLARS:
        a = answers.get(key)
        lines.append(f"{key}: " + (f"[{a.get('quality')}] {a.get('summary')}" if a else "not recorded yet"))
    details = answers.get("details")
    lines.append("details: " + (json.dumps(details, ensure_ascii=False) if details else "not recorded yet"))
    return "<onboarding_state>\n" + "\n".join(lines) + "\n</onboarding_state>"


def opening_text():
    """The first message of the interview (no model call)."""
    return prompt("onboarding_opening")


def reply(member, memory, history):
    """Continue the interview. history ends with the member's message.

    Updates memory.onboarding_* through the tools (staged; the route commits).
    Returns {"reply", "draft" (or None), "model", "usage"}.
    """
    answers = dict(memory.onboarding_answers or {})
    draft = {}

    def advance(step):
        memory.onboarding_step = max(memory.onboarding_step or 0, step)

    def handle_tool(name, args):
        if name == "record_pillar":
            pillar = args.get("pillar")
            summary = args.get("summary")
            quality = args.get("quality")
            if pillar not in coach_store.PILLARS:
                raise ToolError("pillar must be accomplish, looking_for or holding_back.")
            if not isinstance(summary, str) or not summary.strip():
                raise ToolError("Include the member's answer in summary.")
            if quality not in ("strong", "light"):
                raise ToolError("quality must be strong or light.")
            answers[pillar] = {"summary": summary.strip()[:MAX_PILLAR_SUMMARY], "quality": quality,
                               "updated_at": coach_store.now_iso()}
            memory.onboarding_answers = dict(answers)
            advance(coach_store.PILLARS.index(pillar) + 1)
            return {"recorded": pillar, "step": memory.onboarding_step}

        if name == "record_details":
            details = coach_store.clean_facts({
                "location": args.get("location"),
                "skills": args.get("skills"),
                "interests": args.get("interests"),
            })
            if not details:
                raise ToolError("Include a location, skills or interests.")
            answers["details"] = details
            memory.onboarding_answers = dict(answers)
            advance(4)
            return {"recorded": "details", "step": memory.onboarding_step}

        if name == "propose_write_draft":
            missing = [k for k in coach_store.PILLARS if k not in answers]
            if missing:
                raise ToolError(f"Record these pillars first: {', '.join(missing)}.")
            entries = {}
            for key in coach_store.PILLARS:
                text = args.get(key)
                if not isinstance(text, str) or not text.strip():
                    raise ToolError(f"Write the {key} entry.")
                entries[key] = text.strip()[:MAX_DRAFT_CHARS]
            draft.clear()
            draft.update(entries)
            memory.onboarding_status = "review"
            advance(4)
            return {"proposed": True, "note": "The member now sees the draft to review, edit and save."}

        raise ToolError(f"Unknown tool: {name}")

    if memory.onboarding_status == "not_started":
        memory.onboarding_status = "in_progress"

    context = f"{profile_block(member)}\n{_state_block(memory)}"
    messages = build_messages(context, history)
    result = converse(member, prompt("onboarding_system"), TOOLS, messages, handle_tool,
                      tag="RepOnboarding", max_tokens=6000)

    text = result["text"]
    if result["stop_reason"] == "refusal" or not text:
        text = ("Sorry, I couldn't finish that. Could you say that again in a few words?"
                if not draft else "Here's a draft of your Write section to review.")
    return {
        "reply": text,
        "draft": write_draft_payload(draft) if draft else None,
        "model": result["model"],
        "usage": result["usage"],
    }


def write_draft_payload(entries):
    """The review card's payload: one entry per pillar, with the title it's saved under."""
    return {
        "write_draft": {
            "entries": [
                {"pillar": key, "title": coach_store.PILLAR_TITLES[key], "content": entries[key]}
                for key in coach_store.PILLARS
            ],
        },
        "status": "pending",
    }


def complete(member, memory, saved_entries=None, summarize=True):
    """The member saved their Write section: finish onboarding and fill in what Coach knows.

    saved_entries: {pillar: text} as the member saved it (after any edits). Staged; the route
    commits. Writing the summary is best-effort (one model call, skipped when summarize is
    False); onboarding completes either way.
    """
    answers = memory.onboarding_answers or {}
    facts = {}
    for key in coach_store.PILLARS:
        text = (saved_entries or {}).get(key) or (answers.get(key) or {}).get("summary")
        if text:
            facts[key] = text
    facts.update(answers.get("details") or {})
    coach_store.merge_facts(memory, facts)

    now = datetime.utcnow()
    memory.onboarding_status = "complete"
    memory.onboarding_step = 4
    memory.onboarding_completed_at = now
    memory.write_saved_at = now

    if not summarize:
        return
    try:
        result = converse(
            member,
            prompt("memory_narrative"),
            [],
            [{"role": "user", "content": json.dumps(memory.facts or {}, ensure_ascii=False)}],
            lambda name, args: {},
            tag="RepOnboarding-summary",
            max_tokens=600,
        )
        if result["text"] and result["stop_reason"] != "refusal":
            memory.narrative = result["text"].strip()[:coach_store.MAX_NARRATIVE_CHARS]
    except Exception:
        # The summary is a nicety; Coach still has the facts.
        logger.exception("Rep Onboarding summary failed for user %s", member.id)
