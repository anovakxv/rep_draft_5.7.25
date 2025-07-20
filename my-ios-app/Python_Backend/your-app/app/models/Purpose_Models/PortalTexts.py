# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from app import db
from datetime import datetime

class PortalText(db.Model):
    __tablename__ = 'portals_texts'

    id = db.Column(db.Integer, primary_key=True)
    portal_id = db.Column(db.Integer, db.ForeignKey('portals.id', ondelete="CASCADE"), nullable=False, index=True)
    title = db.Column(db.String(255), nullable=False)
    text = db.Column(db.Text, nullable=True)
    section = db.Column(db.String(64), nullable=True, index=True)  # e.g., 'about', 'mission', 'faq'
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    portal = db.relationship('Portal', backref='portal_texts')

    def as_dict(self):
        return {
            'id': self.id,
            'portal_id': self.portal_id,
            'title': self.title,
            'text': self.text,
            'section': self.section,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
        }
    def __repr__(self):
        return f"<PortalText id={self.id} portal_id={self.portal_id} title={self.title} section={self.section}>"