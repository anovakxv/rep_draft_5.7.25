# Rep
# Copyright (c) 2026 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: February 2026

from app import db
from datetime import datetime

class PhotoReaction(db.Model):
    __tablename__ = 'photo_reactions'

    id = db.Column(db.Integer, primary_key=True)
    photo_id = db.Column(db.Integer, db.ForeignKey('user_photos.id', ondelete="CASCADE"), nullable=False, index=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete="CASCADE"), nullable=False, index=True)
    emoji = db.Column(db.String(10), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    # Relationships
    photo = db.relationship('UserPhoto', backref='reactions')
    user = db.relationship('User', backref='photo_reactions')

    # One emoji type per user per photo
    __table_args__ = (
        db.UniqueConstraint('photo_id', 'user_id', 'emoji', name='unique_user_emoji_per_photo'),
    )

    def __repr__(self):
        return f"<PhotoReaction id={self.id} photo_id={self.photo_id} user_id={self.user_id} emoji={self.emoji}>"

    def as_dict(self):
        return {
            "id": self.id,
            "photo_id": self.photo_id,
            "user_id": self.user_id,
            "emoji": self.emoji,
            "created_at": self.created_at.isoformat() + 'Z' if self.created_at else None,
            "user_name": f"{self.user.fname or ''} {self.user.lname or ''}".strip() if self.user else ""
        }
