
from app import db

class Portal(db.Model):
    __tablename__ = 'portals'

    id = db.Column(db.Integer, primary_key=True)
    users_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)  # Creator/owner
    lead_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)
    name = db.Column(db.String(255), nullable=False)
    subtitle = db.Column(db.String(255), nullable=True)
    categories_id = db.Column(db.Integer, db.ForeignKey('categories.id'), nullable=True)
    cities_id = db.Column(db.Integer, db.ForeignKey('cities.id'), nullable=True)
    about = db.Column(db.Text, nullable=True)

    # Add relationships if you want to access related objects easily
    creator = db.relationship('User', foreign_keys=[users_id])
    lead = db.relationship('User', foreign_keys=[lead_id])
    category = db.relationship('Category', foreign_keys=[categories_id])
    city = db.relationship('City', foreign_keys=[cities_id])

    def __repr__(self):
        return f"<Portal {self.id} {self.name}>"
    
    