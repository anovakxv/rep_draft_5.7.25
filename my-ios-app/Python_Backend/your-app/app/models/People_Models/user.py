from app import db
from datetime import datetime
from flask_login import UserMixin

class User(UserMixin, db.Model):
    __tablename__ = 'users'

    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(255), unique=True, nullable=False)
    about = db.Column(db.Text, nullable=True)
    broadcast = db.Column(db.Text, nullable=True)
    phone = db.Column(db.String(50), nullable=True, index=True)
    cities_id = db.Column(db.Integer, db.ForeignKey('cities.id'), nullable=True)
    users_types_id = db.Column(db.Integer, db.ForeignKey('user_types.id'), nullable=True)
    password = db.Column(db.String(255), nullable=False)
    fname = db.Column(db.String(100), nullable=True)
    lname = db.Column(db.String(100), nullable=True)
    username = db.Column(db.String(100), unique=True, nullable=False)
    confirmed = db.Column(db.Boolean, default=True)
    device_token = db.Column(db.String(255), nullable=True)
    twitter_id = db.Column(db.String(100), nullable=True)
    manual_city = db.Column(db.String(100), nullable=True)
    other_skill = db.Column(db.String(255), nullable=True)
    lat = db.Column(db.Float, nullable=True)
    lng = db.Column(db.Float, nullable=True)
    last_login = db.Column(db.DateTime, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    email_verification_token = db.Column(db.String(128), nullable=True)
    profile_picture_url = db.Column(db.String(512), nullable=True)

    # Relationships
    city = db.relationship('City', backref='users')
    user_type = db.relationship('UserType', backref='users')

    def __repr__(self):
        return f"<User id={self.id} username={self.username}>"

    def get_skills(self):
        # TODO: Replace with real logic to fetch user skills
        # For now, use other_skill as a single skill if present
        if self.other_skill:
            return [self.other_skill]
        return ["Leadership", "Marketing", "Fundraising"]

    def as_dict(self, include_message=False, last_message=None, last_message_date=None):
        return {
            "id": self.id,
            "fname": self.fname or "",
            "lname": self.lname or "",
            "full_name": f"{self.fname or ''} {self.lname or ''}".strip(),
            "username": self.username,
            "about": self.about or "",
            "broadcast": self.broadcast or "",
            "profile_picture_url": self.profile_picture_url or "",
            "user_type": self.user_type.name if self.user_type else "",
            "city": self.city.name if self.city else "",
            "skills": self.get_skills(),
            "last_login": self.last_login.isoformat() if self.last_login else None,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
            # Messaging fields for chat list
            "last_message": last_message if include_message else None,
            "last_message_date": last_message_date.isoformat() if include_message and last_message_date else None,
        }
    