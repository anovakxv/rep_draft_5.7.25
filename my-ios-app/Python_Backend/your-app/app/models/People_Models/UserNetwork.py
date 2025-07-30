# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from app import db
from datetime import datetime

class UserNetwork(db.Model):
    __tablename__ = 'users_network'

    id = db.Column(db.Integer, primary_key=True)
    users_id1 = db.Column(db.Integer, db.ForeignKey('users.id', ondelete="CASCADE"), nullable=False)
    users_id2 = db.Column(db.Integer, db.ForeignKey('users.id', ondelete="CASCADE"), nullable=False)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)
    status = db.Column(db.String(20), default='pending')  # e.g., 'pending', 'accepted', 'blocked'
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    __table_args__ = (
        db.UniqueConstraint('users_id1', 'users_id2', name='uq_users_network_pair'),
        db.Index('ix_users_network_pair', 'users_id1', 'users_id2'),
    )

    user1 = db.relationship('User', foreign_keys=[users_id1], backref='networks_initiated')
    user2 = db.relationship('User', foreign_keys=[users_id2], backref='networks_received')

    def __repr__(self):
        return f"<UserNetwork id={self.id} users_id1={self.users_id1} users_id2={self.users_id2}>"

    def as_dict(self):
        return {
            "id": self.id,
            "users_id1": self.users_id1,
            "users_id2": self.users_id2,
            "status": self.status,
            "timestamp": self.timestamp.isoformat() + 'Z' if self.timestamp else None,
            "updated_at": self.updated_at.isoformat() + 'Z' if self.updated_at else None,
        }
    
from flask import Blueprint, request, jsonify, g
from app import db
from app.models.People_Models.BlockedUser import BlockedUser
from app.utils.auth import jwt_required

user_bp = Blueprint('block_user', __name__)

@user_bp.route('/block', methods=['POST'])
@jwt_required
def block_user():
    blocker_id = g.current_user.id
    blocked_id = request.json.get('users_id')
    if not blocked_id or blocker_id == blocked_id:
        return jsonify({'error': 'Invalid user'}), 400
    if BlockedUser.query.filter_by(blocker_id=blocker_id, blocked_id=blocked_id).first():
        return jsonify({'result': 'already blocked'})
    db.session.add(BlockedUser(blocker_id=blocker_id, blocked_id=blocked_id))
    db.session.commit()
    return jsonify({'result': 'blocked'})

@user_bp.route('/unblock', methods=['POST'])
@jwt_required
def unblock_user():
    blocker_id = g.current_user.id
    blocked_id = request.json.get('users_id')
    block = BlockedUser.query.filter_by(blocker_id=blocker_id, blocked_id=blocked_id).first()
    if block:
        db.session.delete(block)
        db.session.commit()
    return jsonify({'result': 'unblocked'})
   