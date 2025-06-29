from app import db

class MessagesRead(db.Model):
    __tablename__ = 'messages_read'
    id = db.Column(db.Integer, primary_key=True)
    users_id = db.Column(db.Integer, nullable=False)
    messages_id = db.Column(db.Integer, nullable=False)
    