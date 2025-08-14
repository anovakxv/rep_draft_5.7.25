# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from app import db
from datetime import datetime

class GoalPreInvite(db.Model):
    __tablename__ = 'goals_pre_invites'

    id = db.Column(db.Integer, primary_key=True)
    users_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete="CASCADE"), nullable=False)
    goals_id = db.Column(db.Integer, db.ForeignKey('goals.id', ondelete="CASCADE"), nullable=False)
    type = db.Column(db.String(20), nullable=False)  # 'email', 'phone', 'fb'
    identifier = db.Column(db.String(255), nullable=False)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)

    user = db.relationship('User', backref='goal_pre_invites')
    # goal = db.relationship('Goal', backref='pre_invites')

    def __repr__(self):
        return f"<GoalPreInvite id={self.id} goal_id={self.goals_id} type={self.type} identifier={self.identifier}>"
    
    def as_dict(self):
        return {
            "id": self.id,
            "users_id": self.users_id,
            "goals_id": self.goals_id,
            "type": self.type,
            "identifier": self.identifier,
            "timestamp": self.timestamp.isoformat() if self.timestamp else None
        }    
    