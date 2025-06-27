# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025'

from app import db
from datetime import datetime

class UserType(db.Model):
    __tablename__ = 'user_types'

    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(100), unique=True, nullable=False)
    description = db.Column(db.String(255), nullable=True)
    visible = db.Column(db.Boolean, default=True)  # Optional
    created_at = db.Column(db.DateTime, default=datetime.utcnow)  # Optional

    def __repr__(self):
        return f"<UserType id={self.id} title={self.title}>"
    