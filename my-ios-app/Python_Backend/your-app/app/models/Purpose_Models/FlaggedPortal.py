from app import db
from datetime import datetime

class FlaggedPortal(db.Model):
    __tablename__ = 'flagged_portals'
    id = db.Column(db.Integer, primary_key=True)
    flagger_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete="CASCADE"), nullable=False)
    portal_id = db.Column(db.Integer, db.ForeignKey('portals.id', ondelete="CASCADE"), nullable=False)
    reason = db.Column(db.String(255), nullable=True)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)

    __table_args__ = (
        db.UniqueConstraint('flagger_id', 'portal_id', name='uq_flagged_portal_pair'),
    )