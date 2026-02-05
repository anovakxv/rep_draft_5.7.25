# Rep
# Copyright (c) 2026 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: February 2026

from app import db
from datetime import datetime

S3_BASE_URL = "https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/"

class PhotoComment(db.Model):
    __tablename__ = 'photo_comments'

    id = db.Column(db.Integer, primary_key=True)
    photo_id = db.Column(db.Integer, db.ForeignKey('user_photos.id', ondelete="CASCADE"), nullable=False, index=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete="CASCADE"), nullable=False, index=True)
    text = db.Column(db.String(1000), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    photo = db.relationship('UserPhoto', backref='comments')
    user = db.relationship('User', backref='photo_comments')

    def __repr__(self):
        return f"<PhotoComment id={self.id} photo_id={self.photo_id} user_id={self.user_id}>"

    def as_dict(self):
        # Patch profile picture URL
        profile_pic = self.user.profile_picture_url if self.user else None
        if profile_pic and not profile_pic.startswith("http"):
            profile_pic = S3_BASE_URL + profile_pic
        if not profile_pic or str(profile_pic).strip() == "":
            profile_pic = None

        return {
            "id": self.id,
            "photo_id": self.photo_id,
            "user_id": self.user_id,
            "text": self.text,
            "created_at": self.created_at.isoformat() + 'Z' if self.created_at else None,
            "updated_at": self.updated_at.isoformat() + 'Z' if self.updated_at else None,
            "user_name": f"{self.user.fname or ''} {self.user.lname or ''}".strip() if self.user else "",
            "profile_picture_url": profile_pic
        }
