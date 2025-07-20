# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from app import db
from datetime import datetime

class Write(db.Model):
    __tablename__ = 'writes'

    id = db.Column(db.Integer, primary_key=True)
    users_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete="CASCADE"), nullable=False, index=True)
    title = db.Column(db.String(255), nullable=True)  # Optional title for each write block
    content = db.Column(db.Text, nullable=False)
    order = db.Column(db.Integer, nullable=True, default=0)  # For ordering blocks in the UI
    status = db.Column(db.String(20), default='published')  # e.g., 'draft', 'published', 'archived'
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = db.relationship('User', backref='writes')

    def __repr__(self):
        return f"<Write id={self.id} user_id={self.users_id} title={self.title}>"
    
    def as_dict(self):
        return {
            "id": self.id,
            "users_id": self.users_id,
            "title": self.title,
            "content": self.content,
            "order": self.order,
            "status": self.status,
            "created_at": self.created_at.isoformat() + 'Z' if self.created_at else None,
            "updated_at": self.updated_at.isoformat() + 'Z' if self.updated_at else None,
        }    