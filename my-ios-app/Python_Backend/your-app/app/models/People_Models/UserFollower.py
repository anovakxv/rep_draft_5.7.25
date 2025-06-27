# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from app import db
from datetime import datetime

class UserFollower(db.Model):
    __tablename__ = 'users_followers'

    id = db.Column(db.Integer, primary_key=True)
    users_id1 = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)  # follower
    users_id2 = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)  # followed
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)

    # Optional: status field for follow requests
    # status = db.Column(db.String(20), default='accepted')  # e.g., 'pending', 'accepted', 'blocked'

    __table_args__ = (
        db.UniqueConstraint('users_id1', 'users_id2', name='uq_users_followers_pair'),
        db.Index('ix_users_followers_pair', 'users_id1', 'users_id2'),
    )

    follower = db.relationship('User', foreign_keys=[users_id1], backref='following')
    followed = db.relationship('User', foreign_keys=[users_id2], backref='followers')

    def __repr__(self):
        return f"<UserFollower id={self.id} follower={self.users_id1} followed={self.users_id2}>"
    