# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from app import db
from datetime import datetime

class PortalsUsersShare(db.Model):
    __tablename__ = 'portals_users_share'

    id = db.Column(db.Integer, primary_key=True)
    portals_id = db.Column(db.Integer, db.ForeignKey('portals.id'), nullable=False, index=True)
    users_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    shared_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    # Relationships
    portal = db.relationship('Portal', backref=db.backref('shared_users', lazy='dynamic', cascade="all, delete-orphan"))
    user = db.relationship('User', backref=db.backref('shared_portals', lazy='dynamic', cascade="all, delete-orphan"))

    def __repr__(self):
        return f"<PortalsUsersShare id={self.id} portals_id={self.portals_id} users_id={self.users_id}>"

    def as_dict(self):
        return {
            'id': self.id,
            'portals_id': self.portals_id,
            'users_id': self.users_id,
            'shared_at': self.shared_at.isoformat() if self.shared_at else None,
            # Optionally include related objects:
            # 'portal': self.portal.as_card_dict() if self.portal else None,
            # 'user': self.user.as_dict() if self.user else None,
        }
        