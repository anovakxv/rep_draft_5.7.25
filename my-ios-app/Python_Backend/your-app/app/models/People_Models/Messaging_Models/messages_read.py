from app import db

class MessagesRead(db.Model):
    __tablename__ = 'messages_read'
    id = db.Column(db.Integer, primary_key=True)
    users_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete="CASCADE"), nullable=False)
    messages_id = db.Column(db.Integer, db.ForeignKey('direct_messages.id', ondelete="CASCADE"), nullable=False)