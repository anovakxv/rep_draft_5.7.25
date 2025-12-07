# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: December 2025
# ENHANCEMENT: Add emoji reactions to messages

from app import db
from datetime import datetime

class MessageReaction(db.Model):
    __tablename__ = 'message_reactions'

    id = db.Column(db.Integer, primary_key=True)
    message_id = db.Column(db.Integer, db.ForeignKey('direct_messages.id', ondelete="CASCADE"), nullable=False, index=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete="CASCADE"), nullable=False, index=True)
    emoji = db.Column(db.String(10), nullable=False)  # Stores emoji character (e.g., '👍', '❤️', '😂')
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    # Relationships
    message = db.relationship('DirectMessage', backref='reactions')
    user = db.relationship('User', backref='message_reactions')

    # Unique constraint: one user can only add each emoji once per message
    __table_args__ = (
        db.UniqueConstraint('message_id', 'user_id', 'emoji', name='unique_user_emoji_per_message'),
        db.Index('idx_message_reactions_message_id', 'message_id'),
        db.Index('idx_message_reactions_user_id', 'user_id'),
    )

    def __repr__(self):
        return f"<MessageReaction id={self.id} message_id={self.message_id} user_id={self.user_id} emoji={self.emoji}>"

    def as_dict(self):
        return {
            "id": self.id,
            "message_id": self.message_id,
            "user_id": self.user_id,
            "emoji": self.emoji,
            "created_at": self.created_at.isoformat() + 'Z' if self.created_at else None,
            "user_name": f"{self.user.fname or ''} {self.user.lname or ''}".strip() if self.user else ""
        }
