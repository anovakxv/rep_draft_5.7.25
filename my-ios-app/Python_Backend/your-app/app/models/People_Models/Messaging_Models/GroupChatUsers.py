# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from app import db
from datetime import datetime

class ChatsUsers(db.Model):
    __tablename__ = 'chats_users'

    id = db.Column(db.Integer, primary_key=True)
    chats_id = db.Column(db.Integer, db.ForeignKey('chats.id'), nullable=False)
    users_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    joined_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    # Optionally: role (admin/member), status, etc.

    # Relationships
    chat = db.relationship('Chats', backref='memberships')
    user = db.relationship('User', backref='group_memberships')

    def as_dict(self):
        return {
            "id": self.id,
            "chats_id": self.chats_id,
            "users_id": self.users_id,
            "joined_at": self.joined_at.isoformat() + 'Z'
            }