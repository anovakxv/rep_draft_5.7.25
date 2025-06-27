# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from app import db

class GoalTeam(db.Model):
    __tablename__ = 'goals_team'

    id = db.Column(db.Integer, primary_key=True)
    users_id1 = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)  # inviter
    users_id2 = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)  # invitee/member
    goals_id = db.Column(db.Integer, db.ForeignKey('goals.id'), nullable=False)
    confirmed = db.Column(db.Integer, default=0)  # 1=accepted, 0=pending, -1=declined
    read1 = db.Column(db.Boolean, default=False)
    read2 = db.Column(db.Boolean, default=False)
    timestamp = db.Column(db.DateTime)

    inviter = db.relationship('User', foreign_keys=[users_id1])
    member = db.relationship('User', foreign_keys=[users_id2])
    # goal = db.relationship('Goal', backref='team_members')

    def __repr__(self):
        return f"<GoalTeam goal_id={self.goals_id} user_id={self.users_id2} confirmed={self.confirmed}>"
        