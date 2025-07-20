# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from app import db
from datetime import datetime

class UserSkill(db.Model):
    __tablename__ = 'users_skills'

    id = db.Column(db.Integer, primary_key=True)
    users_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete="CASCADE"), nullable=False)
    skills_id = db.Column(db.Integer, db.ForeignKey('skills.id', ondelete="CASCADE"), nullable=False)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)  # Optional

    __table_args__ = (
        db.UniqueConstraint('users_id', 'skills_id', name='uq_users_skills_pair'),
        db.Index('ix_users_skills_pair', 'users_id', 'skills_id'),
    )

    user = db.relationship('User', backref='user_skills')
    skill = db.relationship('Skill', backref='user_skills')

    def __repr__(self):
        return f"<UserSkill id={self.id} users_id={self.users_id} skills_id={self.skills_id}>"
    