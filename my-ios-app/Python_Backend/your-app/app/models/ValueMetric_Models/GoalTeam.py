# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from app import db

class GoalTeam(db.Model):
    __tablename__ = 'goals_team'

    id = db.Column(db.Integer, primary_key=True)
    users_id1 = db.Column(db.Integer, db.ForeignKey('users.id', ondelete="CASCADE"), nullable=False)
    users_id2 = db.Column(db.Integer, db.ForeignKey('users.id', ondelete="CASCADE"), nullable=False)
    goals_id = db.Column(db.Integer, db.ForeignKey('goals.id', ondelete="CASCADE"), nullable=False)
    confirmed = db.Column(db.Integer, default=0)  # 1=accepted, 0=pending, -1=declined
    read1 = db.Column(db.Boolean, default=False)
    read2 = db.Column(db.Boolean, default=False)
    timestamp = db.Column(db.DateTime)

    inviter = db.relationship('User', foreign_keys=[users_id1])
    member = db.relationship('User', foreign_keys=[users_id2])
    # goal = db.relationship('Goal', backref='team_members')

    def __repr__(self):
        return f"<GoalTeam goal_id={self.goals_id} user_id={self.users_id2} confirmed={self.confirmed}>"
       
    def as_dict(self):
        return {
            "id": self.id,
            "users_id1": self.users_id1,
            "users_id2": self.users_id2,
            "goals_id": self.goals_id,
            "confirmed": self.confirmed,
            "read1": self.read1,
            "read2": self.read2,
            "timestamp": self.timestamp.isoformat() if self.timestamp else None
        }
    