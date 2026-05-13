# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from app import db
from datetime import datetime

class GroupMessage(db.Model):
    __tablename__ = 'group_messages'

    id = db.Column(db.Integer, primary_key=True)
    chat_id = db.Column(db.Integer, db.ForeignKey('chats.id', ondelete="CASCADE"), nullable=False, index=True)
    sender_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete="CASCADE"), nullable=False, index=True)
    text = db.Column(db.Text, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    edited_at = db.Column(db.DateTime, nullable=True)  # NEW: Timestamp of last edit (NULL if never edited)
    is_deleted = db.Column(db.Boolean, default=False, nullable=False)  # NEW: Soft delete flag

    # Relationships
    sender = db.relationship('User', backref='sent_group_messages')
    # passive_deletes=True lets DB handle cascade without SQLAlchemy issuing UPDATEs
    chat = db.relationship('Chats', backref=db.backref('messages', passive_deletes=True))

    def as_dict(self, current_user_id=None):
        # Build grouped reactions (same format as toggle_reaction endpoint)
        reactions_grouped = {}
        for reaction in self.reactions:
            emoji = reaction.emoji
            if emoji not in reactions_grouped:
                reactions_grouped[emoji] = {
                    "emoji": emoji,
                    "count": 0,
                    "userReacted": False,
                    "users": []
                }
            reactions_grouped[emoji]["count"] += 1
            if current_user_id and reaction.user_id == current_user_id:
                reactions_grouped[emoji]["userReacted"] = True
            reactions_grouped[emoji]["users"].append({
                "user_id": reaction.user_id,
                "user_name": f"{reaction.user.fname or ''} {reaction.user.lname or ''}".strip() if reaction.user else ""
            })

        return {
            "id": self.id,
            "chat_id": self.chat_id,
            "sender_id": self.sender_id,
            "text": self.text,
            "created_at": self.created_at.isoformat() + 'Z',
            "sender": self.sender.as_dict() if self.sender else None,
            # NEW: Edit and deletion fields
            "edited_at": self.edited_at.strftime("%Y-%m-%dT%H:%M:%SZ") if self.edited_at else None,
            "is_edited": self.edited_at is not None,  # Convenience flag
            "is_deleted": self.is_deleted,
            # NEW: Reactions (always included, iOS ignores unknown fields)
            "reactions": list(reactions_grouped.values())
        }
