# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: December 2025
# ENHANCEMENT: Add file attachments to messages

from app import db
from datetime import datetime

class MessageAttachment(db.Model):
    __tablename__ = 'message_attachments'

    id = db.Column(db.Integer, primary_key=True)
    message_id = db.Column(db.Integer, db.ForeignKey('direct_messages.id', ondelete="CASCADE"), nullable=False, index=True)
    file_url = db.Column(db.String(500), nullable=False)  # S3 URL or file path
    file_name = db.Column(db.String(255), nullable=False)  # Original filename
    file_type = db.Column(db.String(100), nullable=True)  # MIME type (e.g., 'image/jpeg', 'application/pdf')
    file_size = db.Column(db.Integer, nullable=True)  # Size in bytes
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    # Relationships
    message = db.relationship('DirectMessage', backref='attachments')

    __table_args__ = (
        db.Index('idx_message_attachments_message_id', 'message_id'),
    )

    def __repr__(self):
        return f"<MessageAttachment id={self.id} message_id={self.message_id} file_name={self.file_name}>"

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
