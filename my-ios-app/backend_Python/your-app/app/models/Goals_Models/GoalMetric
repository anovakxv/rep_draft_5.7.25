
from app import db

class GoalMetric(db.Model):
    __tablename__ = 'goal_metrics'

    id = db.Column(db.Integer, primary_key=True)
    goal_types_id = db.Column(db.Integer, db.ForeignKey('goal_types.id'), nullable=False)
    title = db.Column(db.String(100), nullable=False)

    goal_type = db.relationship('GoalType', backref='metrics')

    def __repr__(self):
        return f"<GoalMetric id={self.id} title={self.title}>"
        