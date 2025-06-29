from app import db

# finish attachment workflow for manual goal update

class GoalProgressFile(db.Model):
    __tablename__ = 'goal_progress_files'
    id = db.Column(db.Integer, primary_key=True)
    goal_progress_id = db.Column(db.Integer, nullable=False)
    file_url = db.Column(db.String, nullable=False)

