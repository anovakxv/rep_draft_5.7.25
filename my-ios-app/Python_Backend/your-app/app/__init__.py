from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_socketio import SocketIO
from config import Config

db = SQLAlchemy()
socketio = SocketIO(cors_allowed_origins="*")

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    # --- Import all models so Flask-Migrate can detect them ---

    # People_Models
    from app.models.People_Models import user, UserType, UserSkill, UserNetwork, UserFollower, PasswordUpdater, Skill
    # Write_Models
    from app.models.People_Models.Write_Models import Writings_Model

    # Messaging_Models
    from app.models.People_Models.Messaging_Models import Direct_Messages, Group_Messages, GroupChatMetaData, GroupChatUsers

    # Purpose_Models
    from app.models.Purpose_Models import Portal, PortalEvent, PortalGraphicSection, PortalInvite, PortalTexts, PortalUser

    # s3Content_Models
    from app.models.s3Content_Models import s3Content

    # ValueMetric_Models
    from app.models.ValueMetric_Models import Goal, GoalMetric, GoalPreInvite, GoalProgressLog, GoalTeam, GoalType, ReportingIncrement

    db.init_app(app)
    socketio.init_app(app)

    from app.routes.api import api_bp
    app.register_blueprint(api_bp)

    return app

