# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from app import db
from collections import OrderedDict
from datetime import datetime

class Goal(db.Model):
    """
    Main Goal model representing a measurable objective for a user or team.
    """
    __tablename__ = 'goals'

    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(255), nullable=False)  # Goal title
    subtitle = db.Column(db.String(255))  # Optional subtitle
    users_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete="CASCADE"), nullable=False, index=True)
    portals_id = db.Column(db.Integer, db.ForeignKey('portals.id', ondelete="CASCADE"), nullable=True, index=True)  # Portal/group, now optional
    lead_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete="CASCADE"))
    description = db.Column(db.Text, nullable=False)  # Goal description
    quota = db.Column(db.Float, default=100)  # Target value (float for decimals)
    filled_quota = db.Column(db.Float, default=0)  # Current progress (float for decimals)
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
        if self.goal_type == "Recruiting":
            filled_quota = self.team_members.filter_by(confirmed=1).count()
            return round(filled_quota / self.quota, 2) if self.quota else 0
        latest_log = self.progress_logs.order_by(db.desc('timestamp')).first()
        filled_quota = latest_log.value if latest_log else 0
        return round(filled_quota / self.quota, 2) if self.quota else 0

    def is_quota_reached(self):
        """Returns True if the goal's quota has been reached or exceeded."""
        if self.goal_type == "Recruiting":
            filled_quota = self.team_members.filter_by(confirmed=1).count()
            return filled_quota >= self.quota if self.quota else False
        latest_log = self.progress_logs.order_by(db.desc('timestamp')).first()
        filled_quota = latest_log.value if latest_log else 0
        return filled_quota >= self.quota if self.quota else False

    def can_user_edit(self, user_id):
        """Returns True if the given user_id is allowed to edit this goal."""
        return user_id == self.users_id or user_id == self.lead_id

    def chart_data(self, increment='month', num_periods=4):
        from app.models.ValueMetric_Models.GoalProgressLog import GoalProgressLog

        logs = self.progress_logs.order_by(GoalProgressLog.timestamp.asc()).all()
        cumulative = 0
        grouped = OrderedDict()

        for log in logs:
            if log.timestamp:
                if increment == 'day':
                    label = log.timestamp.strftime('%Y-%m-%d')
                    display_label = log.timestamp.strftime('%d %b')
                elif increment == 'week':
                    label = f"{log.timestamp.year}-W{log.timestamp.isocalendar()[1]}"
                    display_label = f"W{log.timestamp.isocalendar()[1]}"
                else:
                    label = log.timestamp.strftime('%Y-%m')
                    display_label = log.timestamp.strftime('%b')
                cumulative += float(log.added_value or 0)
                # Always keep the latest cumulative value for each increment
                grouped[label] = (cumulative, display_label)

        # Only keep the last num_periods increments
        items = list(grouped.items())[-num_periods:]
        chart_data = [
            {
                "id": idx + 1,
                "value": value,
                "valueLabel": str(value),
                "bottomLabel": display_label
            }
            for idx, (label, (value, display_label)) in enumerate(items)
        ]
        return chart_data

    def as_dict(self, include_team=False, include_progress_logs=False, increment=None, num_periods=4):
        """
        Returns a dict representation of the Goal, suitable for both list and detail views.
        Set include_team/progress_logs True to include team or feed data for detail pages.
        increment: pass 'day', 'week', or 'month' to control chartData grouping.
        num_periods: how many periods to include in chartData (default 4 for list, can override for detail)
        """
        if self.goal_type == "Recruiting":
            filled_quota = self.team_members.filter_by(confirmed=1).count()
        else:
            latest_log = self.progress_logs.order_by(db.desc('timestamp')).first()
            filled_quota = latest_log.value if latest_log else 0

        # Use passed increment, or default to reporting_increment.title or "month"
        chart_increment = increment
        if not chart_increment:
            if self.reporting_increment and hasattr(self.reporting_increment, "title"):
                title = self.reporting_increment.title.lower()
                if "day" in title:
                    chart_increment = "day"
                elif "week" in title:
                    chart_increment = "week"
                elif "month" in title:
                    chart_increment = "month"
            else:
                chart_increment = "month"

        chart_data = [
            {
                "id": idx,
                "value": d["value"],
                "valueLabel": str(d["value"]),
                "bottomLabel": d.get("bottomLabel", "")
            }
            for idx, d in enumerate(self.chart_data(increment=chart_increment, num_periods=num_periods))
        ]

        quota_string = str(self.quota)
        value_string = str(filled_quota)

        team = None
        if include_team:
            team = [
                {
                    "id": tm.member.id,
                    "name": f"{tm.member.fname or ''} {tm.member.lname or ''}".strip(),
                    "imageName": "profile_placeholder"
                }
                for tm in self.team_members if tm.confirmed == 1 and tm.member
            ]

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
            "creatorId": self.users_id,
            "portalId": self.portals_id,
            "title": self.title,
            "subtitle": self.subtitle or "",
            "description": self.description or "",
            "progress": round(filled_quota / self.quota, 2) if self.quota else 0,
            "progressPercent": round(100 * filled_quota / self.quota) if self.quota else 0,
            "quota": self.quota,
            "filledQuota": filled_quota,
            "metricName": self.metric,
            "typeName": self.goal_type,
            "reportingName": self.reporting_increment.title if self.reporting_increment else "",
            "quotaString": quota_string,
            "valueString": value_string,
            "chartData": chart_data,
            "aLatestProgress": a_latest_progress,
            "team": team,
        }