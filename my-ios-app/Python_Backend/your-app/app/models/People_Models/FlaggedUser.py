from app import db
from datetime import datetime

class FlaggedUser(db.Model):
    __tablename__ = 'flagged_users'
    id = db.Column(db.Integer, primary_key=True)
    flagger_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete="CASCADE"), nullable=False)
    flagged_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete="CASCADE"), nullable=False)
    reason = db.Column(db.String(255), nullable=True)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)

    __table_args__ = (
        db.UniqueConstraint('flagger_id', 'flagged_id', name='uq_flagged_pair'),
    )
    