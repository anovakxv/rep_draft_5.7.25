# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from app import db
from datetime import datetime

class Portal(db.Model):
    __tablename__ = 'portals'

    id = db.Column(db.Integer, primary_key=True)
    users_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    lead_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True, index=True)
    name = db.Column(db.String(255), nullable=False, unique=True, index=True)
    subtitle = db.Column(db.String(255), nullable=True)
    categories_id = db.Column(db.Integer, db.ForeignKey('categories.id'), nullable=True, index=True)
    cities_id = db.Column(db.Integer, db.ForeignKey('cities.id'), nullable=True, index=True)
    about = db.Column(db.Text, nullable=True)
    visible = db.Column(db.Boolean, default=True)
    status = db.Column(db.String(32), default='active', index=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    creator = db.relationship('User', foreign_keys=[users_id], backref='created_portals')
    lead = db.relationship('User', foreign_keys=[lead_id], backref='lead_portals')
    category = db.relationship('Category', foreign_keys=[categories_id], backref='portals')
    city = db.relationship('City', foreign_keys=[cities_id], backref='portals')
    graphic_sections = db.relationship('PortalGraphicSection', backref='portal', lazy='select', cascade="all, delete-orphan")

    @property
    def main_image_url(self):
        # Use sorted() since graphic_sections is a list, not a query
        if not self.graphic_sections:
            return None
        first_section = sorted(self.graphic_sections, key=lambda s: (getattr(s, 'position', 0), getattr(s, 'id', 0)))[0]
        if first_section and hasattr(first_section, 's3_files'):
            s3_files = list(first_section.s3_files) if hasattr(first_section.s3_files, '__iter__') else []
            first_files = sorted(s3_files, key=lambda f: getattr(f, 'id', 0))
            first_file = first_files[0] if first_files else None
            if first_file:
                return first_file.url
        return None

    def as_card_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'subtitle': self.subtitle,
            'about': self.about,
            'categories_id': self.categories_id,
            'cities_id': self.cities_id,
            'lead_id': self.lead_id,
            'users_id': self.users_id,
            'visible': self.visible,
            'status': self.status,
            'mainImageUrl': self.main_image_url,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
        }

    def __repr__(self):
        return f"<Portal {self.id} {self.name}>"
    