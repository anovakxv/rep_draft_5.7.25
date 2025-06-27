# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from app import db
from datetime import datetime

class PortalInvite(db.Model):
    __tablename__ = 'portal_invites'

    id = db.Column(db.Integer, primary_key=True)
    portal_id = db.Column(db.Integer, db.ForeignKey('portals.id'), nullable=False)
    invited_by_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    invited_user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)  # If user exists
    invitee_email = db.Column(db.String(255), nullable=True)  # For inviting by email
    invitee_phone = db.Column(db.String(50), nullable=True)   # For inviting by phone
    status = db.Column(db.String(20), default='pending')      # 'pending', 'accepted', 'declined', 'expired'
    sent_at = db.Column(db.DateTime, default=datetime.utcnow)
    responded_at = db.Column(db.DateTime, nullable=True)

    portal = db.relationship('Portal', backref='invites')
    invited_by = db.relationship('User', foreign_keys=[invited_by_id], backref='sent_portal_invites')
    invited_user = db.relationship('User', foreign_keys=[invited_user_id], backref='received_portal_invites')

    def __repr__(self):
        return f"<PortalInvite portal_id={self.portal_id} invited_by={self.invited_by_id} invitee={self.invited_user_id or self.invitee_email or self.invitee_phone} status={self.status}>"
        