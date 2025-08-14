# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from app import db
from datetime import datetime

class DirectMessage(db.Model):
    __tablename__ = 'direct_messages'

    id = db.Column(db.Integer, primary_key=True)
    sender_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete="CASCADE"), nullable=False)
    recipient_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete="CASCADE"), nullable=False)
    text = db.Column(db.Text, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    # Optionally: status, attachments, etc.

    # Relationships
    sender = db.relationship('User', foreign_keys=[sender_id], backref='sent_direct_messages')
    recipient = db.relationship('User', foreign_keys=[recipient_id], backref='received_direct_messages')

    def as_dict(self, read=None):
        ts = self.created_at.strftime("%Y-%m-%dT%H:%M:%SZ")
        return {
            "id": self.id,
            "sender_id": self.sender_id,
            "sender_name": (
                f"{self.sender.fname or ''} {self.sender.lname or ''}".strip()
                if self.sender else ""
            ),
            "recipient_id": self.recipient_id,
            "text": self.text,
            "timestamp": ts,
            "created_at": ts,        # <-- added alias for iOS decoder
            "sender": self.sender.as_dict() if self.sender else None,
            "recipient": self.recipient.as_dict() if self.recipient else None,
            "read": read
        }