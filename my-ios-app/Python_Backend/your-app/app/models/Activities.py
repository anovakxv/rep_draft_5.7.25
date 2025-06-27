# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from app import db
from datetime import datetime

class Activity(db.Model):
    __tablename__ = 'activities'

    id = db.Column(db.Integer, primary_key=True)
    type = db.Column(db.String(64), nullable=False)
    data_type1 = db.Column(db.String(64), nullable=True)
    data_id1 = db.Column(db.Integer, nullable=True)
    users_id1 = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)
    users_id2 = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)
    data_type2 = db.Column(db.String(64), nullable=True)
    data_id2 = db.Column(db.Integer, nullable=True)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)

    def as_dict(self):
        return {
            'id': self.id,
            'type': self.type,
            'data_type1': self.data_type1,
            'data_id1': self.data_id1,
            'users_id1': self.users_id1,
            'users_id2': self.users_id2,
            'data_type2': self.data_type2,
            'data_id2': self.data_id2,
            'timestamp': self.timestamp.isoformat() if self.timestamp else None
        }