# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from app import db
from collections import defaultdict
from datetime import datetime

class Goal(db.Model):
    """
    Main Goal model representing a measurable objective for a user or team.
    """
    __tablename__ = 'goals'

    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(255), nullable=False)  # Goal title
    subtitle = db.Column(db.String(255))  # Optional subtitle
    users_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)  # Creator/owner
    portals_id = db.Column(db.Integer, db.ForeignKey('portals.id'), nullable=True, index=True)  # Portal/group, now optional
    lead_id = db.Column(db.Integer, db.ForeignKey('users.id'))  # Team lead (optional)
    description = db.Column(db.Text, nullable=False)  # Goal description
    quota = db.Column(db.Integer, default=100)  # Target value
    filled_quota = db.Column(db.Integer, default=0)  # Current progress
    quota_is_reached_note = db.Column(db.Boolean, default=False)  # Flag if quota reached

    # Goal type and metric: user selects from allowed types or enters custom for "Other"
    goal_type = db.Column(db.String(50), nullable=False)  # e.g., "Recruiting", "Sales", etc. or custom string for "Other"
    metric = db.Column(db.String(50), nullable=False)     # e.g., "Team Members", "Dollars", etc. or custom string for "Other"

    rep_commission = db.Column(db.Float)  # Optional commission
    reporting_increments_id = db.Column(db.Integer, db.ForeignKey('reporting_increments.id'), nullable=False, index=True)  # Reporting period FK

    # Relationships
    creator = db.relationship('User', foreign_keys=[users_id])
    lead = db.relationship('User', foreign_keys=[lead_id])
    portal = db.relationship('Portal', backref='goals')
    reporting_increment = db.relationship('ReportingIncrement', backref='goals')
    progress_logs = db.relationship('GoalProgressLog', backref='goal', lazy='dynamic')
    team_members = db.relationship('GoalTeam', backref='goal', lazy='dynamic')
    pre_invites = db.relationship('GoalPreInvite', backref='goal', lazy='dynamic')

    def __repr__(self):
        return f"<Goal id={self.id} title={self.title} description={self.description[:20]}>"

    @property
    def progress(self):
        """Returns progress as a float between 0 and 1."""
        return round(self.filled_quota / self.quota, 2) if self.quota else 0

    def is_quota_reached(self):
        """Returns True if the goal's quota has been reached or exceeded."""
        return self.filled_quota >= self.quota if self.quota else False

    def can_user_edit(self, user_id):
        """
        Returns True if the given user_id is allowed to edit this goal.
        Owner or lead can edit.
        """
        return user_id == self.users_id or user_id == self.lead_id

    def chart_data(self, increment='month', num_periods=4):
        """
        Aggregates progress logs for charting.
        increment: 'month', 'week', or 'day'
        num_periods: how many periods to include (e.g., last 4 months)
        """
        from app.models.ValueMetric_Models.GoalProgressLog import GoalProgressLog
        logs = self.progress_logs.order_by(GoalProgressLog.timestamp.asc()).all()
        data = defaultdict(int)
        for log in logs:
            if log.timestamp:
                if increment == 'month':
                    label = log.timestamp.strftime('%b')
                elif increment == 'week':
                    label = f"W{log.timestamp.isocalendar()[1]}"
                elif increment == 'day':
                    label = log.timestamp.strftime('%d %b')
                else:
                    label = log.timestamp.strftime('%b')
                data[label] += log.added_value or 0
        # Only keep the last num_periods
        items = list(data.items())[-num_periods:]
        return [
            {"value": value, "label": label, "color": "#00FF00"}
            for label, value in items
        ]

    def as_dict(self, include_team=False, include_progress_logs=False):
        """
        Returns a dict representation of the Goal, suitable for both list and detail views.
        Set include_team/progress_logs True to include team or feed data for detail pages.
        """
        # Format chart data for Swift
        chart_data = [
            {
                "value": d["value"],
                "valueLabel": str(d["value"]),
                "bottomLabel": d["label"]
            }
            for d in self.chart_data()
        ]

        # Format quota and value strings for display
        quota_string = str(self.quota)
        value_string = str(self.filled_quota)

        # Team info (for detail view)
        team = None
        if include_team:
            team = [
                {
                    "id": tm.member.id,
                    "name": f"{tm.member.fname or ''} {tm.member.lname or ''}".strip(),
                    "imageName": "profile_placeholder"  # Replace with actual image logic if available
                }
                for tm in self.team_members if tm.confirmed == 1 and tm.member
            ]

        # Latest progress logs (for feed in detail view)
        a_latest_progress = None
        if include_progress_logs:
            from app.models.ValueMetric_Models.GoalProgressLog import GoalProgressLog
            logs = self.progress_logs.order_by(GoalProgressLog.timestamp.desc()).limit(4).all()
            a_latest_progress = [
                {
                    "id": log.id,
                    "users_id": log.users_id,
                    "added_value": log.added_value,
                    "note": log.note,
                    "value": log.value,
                    "timestamp": log.timestamp.isoformat() if log.timestamp else None
                }
                for log in logs
            ]

        return {
            "id": self.id,
            "title": self.title,
            "subtitle": self.subtitle or "",
            "description": self.description or "",
            "progress": round(self.filled_quota / self.quota, 2) if self.quota else 0,
            "progressPercent": round(100 * self.filled_quota / self.quota) if self.quota else 0,
            "quota": self.quota,
            "filledQuota": self.filled_quota,
            "metricName": self.metric,
            "typeName": self.goal_type,
            "reportingName": self.reporting_increment.title if self.reporting_increment else "",
            "quotaString": quota_string,
            "valueString": value_string,
            "chartData": chart_data,
            "aLatestProgress": a_latest_progress,
            "team": team,
            # Add more fields as needed
        }
    