# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from app import db

class Skill(db.Model):
    __tablename__ = 'skills'

    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(255), nullable=False)
    parent = db.Column(db.Integer, db.ForeignKey('skills.id'))
    visible = db.Column(db.Boolean, default=True)

    parent_skill = db.relationship('Skill', remote_side=[id], backref='subskills')

    def __repr__(self):
        return f"<Skill id={self.id} title={self.title}>"

    def as_dict(self):
        return {
            "id": self.id,
            "title": self.title
        }
    