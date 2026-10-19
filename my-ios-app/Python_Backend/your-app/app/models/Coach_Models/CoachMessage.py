# Rep
# Copyright (c) 2026 Networked Capital Inc. All rights reserved.
#
# One turn of a member's Rep Coach or Rep Onboarding conversation.
#
# AI data only: kept apart from the member's own content (writes, DMs, group chats).
# The only link to the rest of the schema is user_id. Deleting a row is permanent;
# deleted turns are never sent to the model again.

from datetime import datetime

from app import db
from app.models.Coach_Models.json_type import JSONType

# Allowed values (validated in the API; no DB CHECK constraints, so new values
# can be added without a migration)
THREADS = ('coach', 'onboarding')
ROLES = ('user', 'assistant')
KINDS = ('text', 'write_draft')


class CoachMessage(db.Model):
    __tablename__ = 'coach_messages'
    __table_args__ = (
        # Loading the latest turns of one member's thread
        db.Index('ix_coach_messages_user_thread_created', 'user_id', 'thread', 'created_at'),
    )

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    thread = db.Column(db.String(20), nullable=False, default='coach', server_default='coach')
    role = db.Column(db.String(10), nullable=False)
    kind = db.Column(db.String(20), nullable=False, default='text', server_default='text')
    text = db.Column(db.Text, nullable=False)
    # Structured extras: {"cards": {...}} for Coach suggestions;
    # {"write_draft": {...}, "status": "pending" | "saved" | "discarded"} for the Write review card
    payload = db.Column(JSONType, nullable=True)
    # Assistant turns: which model answered and what it cost
    model = db.Column(db.String(60), nullable=True)
    input_tokens = db.Column(db.Integer, nullable=True)
    output_tokens = db.Column(db.Integer, nullable=True)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)

    user = db.relationship('User')

    def __repr__(self):
        return f"<CoachMessage id={self.id} user_id={self.user_id} thread={self.thread} role={self.role}>"

    def as_dict(self):
        # What the member's app needs; model/token usage stays server-side
        return {
            "id": self.id,
            "thread": self.thread,
            "role": self.role,
            "kind": self.kind,
            "text": self.text,
            "payload": self.payload,
            "created_at": self.created_at.strftime("%Y-%m-%dT%H:%M:%SZ") if self.created_at else None,
        }
