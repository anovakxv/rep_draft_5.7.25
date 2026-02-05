# Rep
# Copyright (c) 2026 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: January 2026

from app import db
from datetime import datetime

class UserPhoto(db.Model):
    __tablename__ = 'user_photos'

    id = db.Column(db.Integer, primary_key=True)
    users_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False, index=True)
    s3_gr_hash = db.Column(db.String(255), db.ForeignKey('s3_content.gr_hash', ondelete='CASCADE'), nullable=False, index=True)
    caption = db.Column(db.String(500), nullable=True)
    position = db.Column(db.Integer, default=0)  # For ordering photos
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    user = db.relationship('User', backref='user_photos')
    s3_content = db.relationship('S3Content')

    def __repr__(self):
        return f"<UserPhoto id={self.id} users_id={self.users_id} s3_gr_hash={self.s3_gr_hash}>"

    def as_dict(self):
        return {
            'id': self.id,
            'url': self.s3_content.url if self.s3_content else None,
            'caption': self.caption,
            'position': self.position,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
        }
