# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from app import db
from datetime import datetime

class PortalEvent(db.Model):
    __tablename__ = 'portal_events'

    id = db.Column(db.Integer, primary_key=True)
    portal_id = db.Column(db.Integer, db.ForeignKey('portals.id'), nullable=False)
    title = db.Column(db.String(255), nullable=False)
    description = db.Column(db.Text, nullable=True)
    location = db.Column(db.String(255), nullable=True)
    start_time = db.Column(db.DateTime, nullable=False)
    end_time = db.Column(db.DateTime, nullable=True)
    created_by_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    portal = db.relationship('Portal', backref='events')
    created_by = db.relationship('User', backref='created_portal_events')

    def __repr__(self):
        return f"<PortalEvent id={self.id} portal_id={self.portal_id} title={self.title}>"
        