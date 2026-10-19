# Rep
# Copyright (c) 2026 Networked Capital Inc. All rights reserved.
#
# What Rep Coach knows about a member, plus their Rep Onboarding progress.
# One row per member, created lazily the first time they use Onboarding or Coach.
#
# AI data only: derived from conversations and clearable by the member. The member's
# own content (e.g. the Write section they approve) lives in `writes`, not here.

from datetime import datetime

from app import db
from app.models.Coach_Models.json_type import JSONType

# Allowed values (validated in the API; no DB CHECK constraints)
ONBOARDING_STATUSES = ('not_started', 'in_progress', 'review', 'complete')
# onboarding_step indexes this list (0-4); it drives the 5-step progress bar
ONBOARDING_STEPS = ('accomplish', 'looking_for', 'holding_back', 'details', 'review')


class CoachMemory(db.Model):
    __tablename__ = 'coach_memories'
    __table_args__ = (
        db.UniqueConstraint('user_id', name='uq_coach_memories_user_id'),
    )

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False)

    # --- Memory (what Coach knows) ---
    # Short AI-written summary injected into Coach's context
    narrative = db.Column(db.Text, nullable=True)
    # Structured facts: accomplish, looking_for, holding_back, location, skills[], interests[]
    facts = db.Column(JSONType, nullable=False, default=dict, server_default='{}')

    # --- Rep Onboarding progress ---
    onboarding_status = db.Column(db.String(20), nullable=False, default='not_started', server_default='not_started')
    onboarding_step = db.Column(db.SmallInteger, nullable=False, default=0, server_default='0')
    # Per pillar: {"summary": str, "quality": "strong" | "light", "updated_at": iso}; plus "details": {location, skills}
    onboarding_answers = db.Column(JSONType, nullable=False, default=dict, server_default='{}')
    onboarding_completed_at = db.Column(db.DateTime, nullable=True)
    # When the member saved the drafted Write section to their profile
    write_saved_at = db.Column(db.DateTime, nullable=True)

    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = db.relationship('User')

    @classmethod
    def for_user(cls, user_id):
        """The member's memory row, created (not yet committed) if they don't have one."""
        memory = cls.query.filter_by(user_id=user_id).first()
        if memory is None:
            memory = cls(user_id=user_id)
            db.session.add(memory)
        return memory

    def __repr__(self):
        return f"<CoachMemory user_id={self.user_id} onboarding={self.onboarding_status}>"

    def as_dict(self):
        def ts(value):
            return value.strftime("%Y-%m-%dT%H:%M:%SZ") if value else None

        return {
            "narrative": self.narrative,
            "facts": self.facts or {},
            "onboarding": {
                "status": self.onboarding_status,
                "step": self.onboarding_step,
                "steps": list(ONBOARDING_STEPS),
                "answers": self.onboarding_answers or {},
                "completed_at": ts(self.onboarding_completed_at),
            },
            "write_saved_at": ts(self.write_saved_at),
            "updated_at": ts(self.updated_at),
        }
