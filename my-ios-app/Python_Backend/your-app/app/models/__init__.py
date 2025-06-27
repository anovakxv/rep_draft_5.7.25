# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_socketio import SocketIO
from config import Config

db = SQLAlchemy()
socketio = SocketIO(cors_allowed_origins="*")

# --- Force SQLAlchemy to register ---
from app.models.Purpose_Models.Category import Category
from app.models.People_Models import User
from app.models.Purpose_Models.City import City
from app.models.Purpose_Models.PortalGraphicSection import PortalGraphicSection
from app.models.s3Content_Models import S3Content
from app.models.ValueMetric_Models import Goal, GoalMetric, GoalPreInvite, GoalProgressLog, GoalTeam, GoalType, ReportingIncrement

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    # --- Import all models so Flask-Migrate can detect them ---
    from app.models.Purpose_Models.Category import Category
   
    # People_Models
    from app.models.People_Models import user, UserType, UserSkill, UserNetwork, UserFollower, PasswordUpdater, Skill

    # Write_Models
    from app.models.People_Models.Write_Models import Writings_Model

    # Messaging_Models
    from app.models.People_Models.Messaging_Models import Direct_Messages, Group_Messages, GroupChatMetaData, GroupChatUsers

    # Purpose_Models
    from app.models.Purpose_Models import Portal, PortalUser, PortalEvent, PortalGraphicSection, PortalInvite, PortalTexts

    # s3Content_Models
    from app.models.s3Content_Models import s3Content

    # ValueMetric_Models
    from app.models.ValueMetric_Models import Goal, GoalMetric, GoalType, GoalTeam, GoalProgressLog, GoalPreInvite, ReportingIncrement

    # Activities
    from app.models import Activities

    db.init_app(app)
    socketio.init_app(app)

    from app.routes.api import api_bp
    app.register_blueprint(api_bp)

    return app

