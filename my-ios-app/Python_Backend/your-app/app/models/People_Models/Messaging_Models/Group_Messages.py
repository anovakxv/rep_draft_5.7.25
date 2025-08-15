# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from app import db
from datetime import datetime

class GroupMessage(db.Model):
    __tablename__ = 'group_messages'

    id = db.Column(db.Integer, primary_key=True)
    chat_id = db.Column(db.Integer, db.ForeignKey('chats.id', ondelete="CASCADE"), nullable=False)
    sender_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete="CASCADE"), nullable=False)
    text = db.Column(db.Text, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    # Relationships
    sender = db.relationship('User', backref='sent_group_messages')
    # passive_deletes=True lets DB handle cascade without SQLAlchemy issuing UPDATEs
    chat = db.relationship('Chats', backref=db.backref('messages', passive_deletes=True))

    def as_dict(self):
        return {
            "id": self.id,
            "chat_id": self.chat_id,
            "sender_id": self.sender_id,
            "text": self.text,
            "created_at": self.created_at.isoformat() + 'Z',
            "sender": self.sender.as_dict() if self.sender else None,
        }
