# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from app import db
from datetime import datetime

class PortalUser(db.Model):
    __tablename__ = 'portal_users'

    id = db.Column(db.Integer, primary_key=True)
    portal_id = db.Column(db.Integer, db.ForeignKey('portals.id', ondelete="CASCADE"), nullable=False, index=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete="CASCADE"), nullable=False, index=True)
    role = db.Column(db.String(32), nullable=False, index=True, default='member')  # 'member', 'lead', 'admin', etc.
    joined_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    __table_args__ = (
        db.UniqueConstraint('portal_id', 'user_id', name='uq_portal_user_pair'),
        db.Index('ix_portal_user_role', 'portal_id', 'user_id', 'role'),
    )

    user = db.relationship('User', backref='portal_users')
    portal = db.relationship('Portal', backref='portal_users')

    def as_dict(self):
        return {
            'id': self.id,
            'portal_id': self.portal_id,
            'user_id': self.user_id,
            'role': self.role,
            'joined_at': self.joined_at.isoformat() if self.joined_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
        }

    def __repr__(self):
        return f"<PortalUser id={self.id} portal_id={self.portal_id} user_id={self.user_id} role={self.role}>"
