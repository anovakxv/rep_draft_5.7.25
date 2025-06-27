# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from app import db
from datetime import datetime

class S3Content(db.Model):
    __tablename__ = 's3_content'

    id = db.Column(db.Integer, primary_key=True)
    gr_hash = db.Column(db.String(255), nullable=False, unique=True, index=True)
    tbl_id = db.Column(db.Integer, nullable=False)
    tbl_index = db.Column(db.Integer, nullable=False)
    key = db.Column(db.String(255), nullable=True)
    url = db.Column(db.String(1024), nullable=True)
    file_type = db.Column(db.String(50), nullable=True)
    file_size = db.Column(db.Integer, nullable=True)
    uploaded_at = db.Column(db.DateTime, default=datetime.utcnow)
    description = db.Column(db.String(255), nullable=True)

    graphic_section_links = db.relationship('PortalGraphicSectionS3Content', back_populates='s3_content')

    def __repr__(self):
        return f"<S3Content id={self.id} gr_hash={self.gr_hash} key={self.key}>"

class PortalGraphicSectionS3Content(db.Model):
    __tablename__ = 'portals_graphic_sections_s3_content'

    id = db.Column(db.Integer, primary_key=True)
    portals_graphic_sections_id = db.Column(db.Integer, db.ForeignKey('portals_graphic_sections.id'), nullable=False, index=True)
    s3_gr_hash = db.Column(db.String(255), db.ForeignKey('s3_content.gr_hash'), nullable=False, index=True)

    graphic_section = db.relationship('PortalGraphicSection', back_populates='s3_contents')
    s3_content = db.relationship('S3Content', back_populates='graphic_section_links')

    __table_args__ = (
        db.UniqueConstraint('portals_graphic_sections_id', 's3_gr_hash', name='uq_section_file'),
    )

    def __repr__(self):
        return f"<PortalGraphicSectionS3Content id={self.id} section_id={self.portals_graphic_sections_id} s3_gr_hash={self.s3_gr_hash}>"
    