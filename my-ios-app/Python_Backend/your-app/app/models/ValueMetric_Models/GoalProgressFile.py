# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: September 2025

from app import db
from datetime import datetime  # Missing import

class GoalProgressFile(db.Model):
    __tablename__ = 'goal_progress_files'
    id = db.Column(db.Integer, primary_key=True)
    goal_progress_id = db.Column(db.Integer, db.ForeignKey('goals_progress_log.id', ondelete="CASCADE"), nullable=False)
    file_url = db.Column(db.String, nullable=False)
    file_name = db.Column(db.String)  # Missing field
    is_image = db.Column(db.Boolean, default=False)  # Missing field
    note = db.Column(db.String)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)