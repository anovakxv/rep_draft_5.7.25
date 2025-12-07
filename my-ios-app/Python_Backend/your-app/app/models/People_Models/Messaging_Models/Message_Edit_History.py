# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: December 2025
# ENHANCEMENT: Track message edit history

from app import db
from datetime import datetime

class MessageEditHistory(db.Model):
    __tablename__ = 'message_edit_history'

    id = db.Column(db.Integer, primary_key=True)
    message_id = db.Column(db.Integer, db.ForeignKey('direct_messages.id', ondelete="CASCADE"), nullable=False, index=True)
    previous_text = db.Column(db.Text, nullable=False)  # Content before the edit
    edited_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    # Relationships
    message = db.relationship('DirectMessage', backref='edit_history')

    __table_args__ = (
        db.Index('idx_message_edit_history_message_id', 'message_id'),
    )

    def __repr__(self):
        return f"<MessageEditHistory id={self.id} message_id={self.message_id} edited_at={self.edited_at}>"

    def as_dict(self):
        return {
            "id": self.id,
            "message_id": self.message_id,
            "previous_text": self.previous_text,
            "edited_at": self.edited_at.isoformat() + 'Z' if self.edited_at else None
        }
