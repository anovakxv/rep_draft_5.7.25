# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from app import db
from datetime import datetime

class GroupMessageEditHistory(db.Model):
    __tablename__ = 'group_message_edit_history'

    id = db.Column(db.Integer, primary_key=True)
    message_id = db.Column(db.Integer, db.ForeignKey('group_messages.id', ondelete="CASCADE"), nullable=False, index=True)
    previous_text = db.Column(db.Text, nullable=False)  # The text before editing
    edited_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    # Relationships
    message = db.relationship('GroupMessage', backref='edit_history')

    def as_dict(self):
        return {
            "id": self.id,
            "message_id": self.message_id,
            "previous_text": self.previous_text,
            "edited_at": self.edited_at.isoformat() + 'Z' if self.edited_at else None
        }
