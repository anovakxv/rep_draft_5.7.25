# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from app import db
from datetime import datetime

class GoalProgressLog(db.Model):
    __tablename__ = 'goals_progress_log'

    id = db.Column(db.Integer, primary_key=True)
    users_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete="CASCADE"), nullable=False, index=True)
    goals_id = db.Column(db.Integer, db.ForeignKey('goals.id', ondelete="CASCADE"), nullable=False, index=True)
    added_value = db.Column(db.Float, nullable=False)  # Changed to Float
    note = db.Column(db.Text)
    value = db.Column(db.Float, default=0)  # Changed to Float
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)

    user = db.relationship('User', backref='goal_progress_logs')
    # goal = db.relationship('Goal', backref='progress_logs')
    # File attachments relationship (if you have a GoalProgressFile model)
    
    progress_files = db.relationship('GoalProgressFile', backref='progress_log', lazy='dynamic')

    def __repr__(self):
        return f"<GoalProgressLog id={self.id} goal_id={self.goals_id} user_id={self.users_id}>"

    def as_dict(self):
        return {
            "id": self.id,
            "users_id": self.users_id,
            "goals_id": self.goals_id,
            "added_value": self.added_value,
            "note": self.note,
            "value": self.value,
            "timestamp": self.timestamp.isoformat() if self.timestamp else None,
            "aAttachments": [
                {
                    "id": f.id,
                    "file_url": f.file_url,
                    "file_name": f.file_name,
                    "is_image": f.is_image,
                    "note": f.note
                } for f in self.progress_files
            ] if hasattr(self, "progress_files") else []
        }