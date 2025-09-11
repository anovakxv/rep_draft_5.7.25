# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025
# ValueMetric_Models/Transaction.py

from app import db
from datetime import datetime

class Transaction(db.Model):
    __tablename__ = 'transactions'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete="CASCADE"), nullable=False, index=True)
    portal_id = db.Column(db.Integer, db.ForeignKey('portals.id', ondelete="CASCADE"), nullable=False, index=True)
    goal_id = db.Column(db.Integer, db.ForeignKey('goals.id', ondelete="CASCADE"), nullable=True, index=True)
    
    amount = db.Column(db.Integer, nullable=False)  # In cents
    currency = db.Column(db.String(3), default='usd')
    transaction_type = db.Column(db.String(50), default='donation')
    message = db.Column(db.Text, nullable=True)
    
    stripe_payment_intent_id = db.Column(db.String(255), unique=True, index=True)
    status = db.Column(db.String(50), default='pending')  # pending, completed, failed
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, onupdate=datetime.utcnow)
    
    # Relationships
    user = db.relationship('User', backref='transactions')
    portal = db.relationship('Portal', backref='transactions')
    goal = db.relationship('Goal', backref='transactions')
    
    def __repr__(self):
        return f"<Transaction id={self.id} amount={self.amount/100} {self.currency} type={self.transaction_type}>"
    
    def as_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "portal_id": self.portal_id,
            "goal_id": self.goal_id,
            "amount": self.amount,
            "currency": self.currency,
            "transaction_type": self.transaction_type,
            "message": self.message,
            "status": self.status,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }