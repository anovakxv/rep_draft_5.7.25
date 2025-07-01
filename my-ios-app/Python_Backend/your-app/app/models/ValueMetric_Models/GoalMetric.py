# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from app import db

# This model is now deprecated in favor of direct goal_type/metric mapping.
# You can safely remove this model if you are no longer using dynamic metrics.

class GoalMetric(db.Model):
    __tablename__ = 'goal_metrics'

    id = db.Column(db.Integer, primary_key=True)
    goal_type = db.Column(db.String(50), nullable=False)  # e.g., "Recruiting", "Sales", etc.
    metric = db.Column(db.String(50), nullable=False)     # e.g., "Team Members", "Dollars", etc.

    def __repr__(self):
        return f"<GoalMetric id={self.id} goal_type={self.goal_type} metric={self.metric}>"
    