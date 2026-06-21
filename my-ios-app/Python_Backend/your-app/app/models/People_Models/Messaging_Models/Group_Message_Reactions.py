# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from app import db
from datetime import datetime

class GroupMessageReaction(db.Model):
    __tablename__ = 'group_message_reactions'

    id = db.Column(db.Integer, primary_key=True)
    message_id = db.Column(db.Integer, db.ForeignKey('group_messages.id', ondelete="CASCADE"), nullable=False, index=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete="CASCADE"), nullable=False, index=True)
    emoji = db.Column(db.String(10), nullable=False)  # Stores emoji character (e.g., "👍", "❤️", "😂")
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    # Relationships
    message = db.relationship('GroupMessage', backref='reactions')
    user = db.relationship('User', backref='group_message_reactions')

    # Prevent duplicate reactions: same user can't add the same emoji twice to the same message
    __table_args__ = (
        db.UniqueConstraint('message_id', 'user_id', 'emoji', name='unique_user_emoji_per_group_message'),
    )

    def as_dict(self):
        # Embedded user must not leak username (== email) — strip it (frontend shows name/avatar).
        user_dict = self.user.as_dict() if self.user else None
        if user_dict:
            user_dict.pop('username', None)
        return {
            "id": self.id,
            "message_id": self.message_id,
            "user_id": self.user_id,
            "emoji": self.emoji,
            "created_at": self.created_at.isoformat() + 'Z' if self.created_at else None,
            "user": user_dict
        }
