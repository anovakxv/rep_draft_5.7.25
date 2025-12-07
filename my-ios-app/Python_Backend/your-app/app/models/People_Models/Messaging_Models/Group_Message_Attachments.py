# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from app import db
from datetime import datetime

class GroupMessageAttachment(db.Model):
    __tablename__ = 'group_message_attachments'

    id = db.Column(db.Integer, primary_key=True)
    message_id = db.Column(db.Integer, db.ForeignKey('group_messages.id', ondelete="CASCADE"), nullable=False, index=True)
    file_url = db.Column(db.String(500), nullable=False)  # S3 URL or path to file
    file_name = db.Column(db.String(255), nullable=False)  # Original filename
    file_type = db.Column(db.String(100), nullable=True)   # MIME type (e.g., "image/png", "application/pdf")
    file_size = db.Column(db.Integer, nullable=True)       # Size in bytes
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    # Relationships
    message = db.relationship('GroupMessage', backref='attachments')

    def as_dict(self):
        return {
            "id": self.id,
            "message_id": self.message_id,
            "file_url": self.file_url,
            "file_name": self.file_name,
            "file_type": self.file_type,
            "file_size": self.file_size,
            "created_at": self.created_at.isoformat() + 'Z' if self.created_at else None
        }
