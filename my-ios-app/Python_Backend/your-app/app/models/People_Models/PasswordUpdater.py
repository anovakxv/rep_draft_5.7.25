# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from app import db

class PasswordUpdater(db.Model):
    __tablename__ = 'password_updaters'

    id = db.Column(db.Integer, primary_key=True)
    users_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    hash = db.Column(db.String(255), nullable=False)
    timestamp = db.Column(db.DateTime)

    user = db.relationship('User', backref='password_updaters')
    