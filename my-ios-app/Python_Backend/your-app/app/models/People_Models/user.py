# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from app import db
from datetime import datetime
from flask_login import UserMixin
from app.models.People_Models.UserType import UserType

class User(UserMixin, db.Model):
    __tablename__ = 'users'

    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(255), unique=True, nullable=False)
    about = db.Column(db.Text, nullable=True)
    broadcast = db.Column(db.Text, nullable=True)
    phone = db.Column(db.String(50), nullable=True, index=True)
    cities_id = db.Column(db.Integer, nullable=True)
    users_types_id = db.Column(
        db.Integer,
        db.ForeignKey('user_types.id', ondelete="SET NULL"),
        nullable=True
    )
    password = db.Column(db.String(255), nullable=False)
    fname = db.Column(db.String(100), nullable=True)
    lname = db.Column(db.String(100), nullable=True)
    username = db.Column(db.String(100), unique=True, nullable=False)
    confirmed = db.Column(db.Boolean, default=True)
    device_token = db.Column(db.String(255), nullable=True)
    twitter_id = db.Column(db.String(100), nullable=True)
    manual_city = db.Column(db.String(100), nullable=True)
    other_skill = db.Column(db.String(255), nullable=True)
    lat = db.Column(db.Float, nullable=True)
    lng = db.Column(db.Float, nullable=True)
    last_login = db.Column(db.DateTime, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    email_verification_token = db.Column(db.String(128), nullable=True)
    profile_picture_url = db.Column(db.String(512), nullable=True)
    stripe_customer_id = db.Column(db.String(128), nullable=True)
    stripe_account_id = db.Column(db.String(128), nullable=True, index=True)
    notification_settings = db.Column(db.JSON, nullable=True)

    # Relationships
    # City = db.relationship('City', backref='users')
    user_type = db.relationship('UserType', backref='users')

    # Example: Add cascade delete to related models (if you want ORM-level cascade)
    # user_skills = db.relationship('UserSkill', backref='user', cascade="all, delete-orphan")
    # networks_initiated = db.relationship('UserNetwork', foreign_keys='UserNetwork.users_id1', backref='user1', cascade="all, delete-orphan")
    # networks_received = db.relationship('UserNetwork', foreign_keys='UserNetwork.users_id2', backref='user2', cascade="all, delete-orphan")
    # writes = db.relationship('Write', backref='user', cascade="all, delete-orphan")
    # sent_direct_messages = db.relationship('DirectMessage', foreign_keys='DirectMessage.sender_id', backref='sender', cascade="all, delete-orphan")
    # received_direct_messages = db.relationship('DirectMessage', foreign_keys='DirectMessage.recipient_id', backref='recipient', cascade="all, delete-orphan")

    def __repr__(self):
        return f"<User id={self.id} username={self.username}>"

    def get_skills(self):
        # Fetch skills from the UserSkill join table
        skills = [us.skill.title for us in self.user_skills if us.skill and us.skill.visible]
        # Optionally include 'other_skill' if present
        if self.other_skill:
            skills.append(self.other_skill)
        return skills

    @property
    def full_name(self):
        return f"{self.fname or ''} {self.lname or ''}".strip()

    def as_dict(self, include_message=False, last_message=None, last_message_date=None):
        return {
            "id": self.id,
            "fname": self.fname or "",
            "lname": self.lname or "",
            "full_name": self.full_name,
            "username": self.username,
            "about": self.about or "",
            "broadcast": self.broadcast or "",
            "profile_picture_url": self.profile_picture_url or "",
            "user_type": self.user_type.title if self.user_type else "",
            "city": self.manual_city or "",
            "skills": self.get_skills(),
            "last_login": self.last_login.isoformat() if self.last_login else None,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
            # Messaging fields for chat list
            "last_message": last_message if include_message else None,
            "last_message_date": last_message_date.isoformat() if include_message and last_message_date else None,
        }