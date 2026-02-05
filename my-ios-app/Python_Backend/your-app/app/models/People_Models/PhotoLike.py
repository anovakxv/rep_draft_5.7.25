# Rep
# Copyright (c) 2026 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: February 2026

from app import db
from datetime import datetime

class PhotoLike(db.Model):
    __tablename__ = 'photo_likes'

    id = db.Column(db.Integer, primary_key=True)
    photo_id = db.Column(db.Integer, db.ForeignKey('user_photos.id', ondelete="CASCADE"), nullable=False, index=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete="CASCADE"), nullable=False, index=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    # Relationships
    photo = db.relationship('UserPhoto', backref='likes')
    user = db.relationship('User', backref='photo_likes')

    # One like per user per photo
    __table_args__ = (
        db.UniqueConstraint('photo_id', 'user_id', name='unique_user_like_per_photo'),
    )

    def __repr__(self):
        return f"<PhotoLike id={self.id} photo_id={self.photo_id} user_id={self.user_id}>"

    def as_dict(self):
        return {
            "id": self.id,
            "photo_id": self.photo_id,
            "user_id": self.user_id,
            "created_at": self.created_at.isoformat() + 'Z' if self.created_at else None,
            "user_name": f"{self.user.fname or ''} {self.user.lname or ''}".strip() if self.user else ""
        }
