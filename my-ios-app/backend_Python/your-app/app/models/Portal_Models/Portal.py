from app import db
from datetime import datetime

class Portal(db.Model):
    __tablename__ = 'portals'

    id = db.Column(db.Integer, primary_key=True)
    users_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)  # Creator/owner
    lead_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True, index=True)
    name = db.Column(db.String(255), nullable=False, unique=True)  # Optional: unique
    subtitle = db.Column(db.String(255), nullable=True)
    categories_id = db.Column(db.Integer, db.ForeignKey('categories.id'), nullable=True, index=True)
    cities_id = db.Column(db.Integer, db.ForeignKey('cities.id'), nullable=True, index=True)
    about = db.Column(db.Text, nullable=True)
    visible = db.Column(db.Boolean, default=True)  # Optional: for soft delete/moderation
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    creator = db.relationship('User', foreign_keys=[users_id], backref='created_portals')
    lead = db.relationship('User', foreign_keys=[lead_id], backref='lead_portals')
    category = db.relationship('Category', foreign_keys=[categories_id], backref='portals')
    city = db.relationship('City', foreign_keys=[cities_id], backref='portals')

    def __repr__(self):
        return f"<Portal {self.id} {self.name}>"
    