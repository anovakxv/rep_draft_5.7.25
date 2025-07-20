# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from app import db
from datetime import datetime

class PortalGraphicSection(db.Model):
    __tablename__ = 'portals_graphic_sections'

    id = db.Column(db.Integer, primary_key=True)
    portals_id = db.Column(db.Integer, db.ForeignKey('portals.id', ondelete="CASCADE"), nullable=False, index=True)
    title = db.Column(db.String(255), nullable=False)
    position = db.Column(db.Integer, nullable=True)  # Optional: for ordering
    content = db.Column(db.Text, nullable=True)      # Optional: for section content
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    s3_contents = db.relationship('PortalGraphicSectionS3Content', back_populates='graphic_section', cascade="all, delete-orphan")

    s3_files = db.relationship(
        'S3Content',
        secondary='portals_graphic_sections_s3_content',
        primaryjoin='PortalGraphicSection.id==PortalGraphicSectionS3Content.portals_graphic_sections_id',
        secondaryjoin='S3Content.gr_hash==PortalGraphicSectionS3Content.s3_gr_hash',
        viewonly=True,
        lazy='dynamic'
        )


    def as_dict(self):
        return {
            'id': self.id,
            'portals_id': self.portals_id,
            'title': self.title,
            'position': self.position,
            'content': self.content,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
            'aFiles': [f.s3_content.as_dict() for f in self.s3_contents] if hasattr(self, 's3_contents') else []
        }

    def __repr__(self):
        return f"<PortalGraphicSection id={self.id} portal_id={self.portals_id}>" 
