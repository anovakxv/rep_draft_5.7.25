# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

import os

# Write the PEM file from the environment variable (if present)
pem_path = "/tmp/apns_cert.pem"
if "APNS_CERT_PEM" in os.environ:
    with open(pem_path, "w") as f:
        f.write(os.environ["APNS_CERT_PEM"])

from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_socketio import SocketIO
from config import Config
from flask_migrate import Migrate
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from app.scheduler import init_scheduler

db = SQLAlchemy()

# Use Redis message queue if REDIS_URL provided (safe if None)
socketio = SocketIO(
    cors_allowed_origins=[
        "https://repnetwork.app",
        "https://www.repnetwork.app",
        "https://repsomething.com",
        "https://www.repsomething.com",
        "http://localhost:5173",
        "http://localhost:5174"
    ],
    message_queue=os.getenv("REDIS_URL"),
    async_mode="eventlet"
)

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    # Fallback secret key (avoid crashes if missing)
    if not app.config.get("SECRET_KEY"):
        app.config["SECRET_KEY"] = os.environ.get("SECRET_KEY", "change-me")

    # CORS configuration - use environment variable for additional origins
    cors_origins = [
        "https://networkedcapital.co",
        "https://repsomething.com",
        "https://www.repsomething.com",
        "http://localhost:5173",
        "http://localhost:5174",
        "http://localhost:5175",
        "http://localhost:5176"
    ]
    # Add production web app origin if specified
    if os.getenv("WEB_APP_ORIGIN"):
        cors_origins.append(os.getenv("WEB_APP_ORIGIN"))

    CORS(app, origins=cors_origins)

    db.init_app(app)
    socketio.init_app(app)
    Migrate(app, db)
    JWTManager(app)

    # --- Import all models so Flask-Migrate can detect them ---
    # People_Models
    from app.models.People_Models import user, UserType, UserSkill, UserNetwork, UserFollower, PasswordUpdater, Skill
    # Write_Models
    from app.models.People_Models.Write_Models import Writings_Model
    # Messaging_Models
    from app.models.People_Models.Messaging_Models import Direct_Messages, Group_Messages, GroupChatMetaData, GroupChatUsers
    # Purpose_Models
    from app.models.Purpose_Models import Portal, PortalEvent, PortalGraphicSection, PortalInvite, PortalTexts, PortalUser, PortalsUsersShare, FlaggedPortal
    # s3Content_Models
    from app.models.s3Content_Models import s3Content
    # ValueMetric_Models
    from app.models.ValueMetric_Models import Goal, GoalMetric, GoalPreInvite, GoalProgressLog, GoalTeam, GoalType, ReportingIncrement
    from app.models.People_Models import FlaggedUser
    from app.models.People_Models.BlockedUser import BlockedUser
    from app.models.ValueMetric_Models.Transaction import Transaction  # <-- Add this line

    # --- Register API Blueprints ---
    from app.routes.api import api_bp
    app.register_blueprint(api_bp)

    # --- User Blueprints (aliased) ---
    from app.routes.User_Routes.AddToNetwork import user_bp as add_to_network_bp
    from app.routes.User_Routes.EditUser import user_bp as edit_user_bp
    from app.routes.User_Routes.Get_Me import user_bp as get_me_bp
    from app.routes.User_Routes.Get_Profile import user_bp as get_profile_bp
    from app.routes.User_Routes.GetSkills import user_bp as get_skills_bp
    from app.routes.User_Routes.GetTotalCounts import user_bp as get_total_counts_bp
    from app.routes.User_Routes.GetUserNetworks import user_bp as get_user_networks_bp
    from app.routes.User_Routes.GetUsers import user_bp as get_users_bp
    from app.routes.User_Routes.LoginActions import user_bp as login_actions_bp
    from app.routes.User_Routes.RegisterUser import user_bp as register_user_bp
    from app.routes.User_Routes.TwitterLogin import user_bp as twitter_login_bp
    from app.routes.User_Routes.Write import user_bp as write_bp
    from app.routes.User_Routes.Get_People import people_bp as get_people_bp
    from app.routes.User_Routes.DeviceToken import user_bp as device_token_bp
    from app.routes.User_Routes.SearchPeople import search_people_bp
    from app.routes.User_Routes.Payments import payments_bp # <-- ADDED
    from app.routes.User_Routes.TriggerDailySummary import admin_bp as trigger_summary_bp

    app.register_blueprint(search_people_bp)
    app.register_blueprint(add_to_network_bp, url_prefix='/api/user')
    app.register_blueprint(edit_user_bp, url_prefix='/api/user')
    app.register_blueprint(get_me_bp, url_prefix='/api/user')
    app.register_blueprint(get_profile_bp, url_prefix='/api/user')
    app.register_blueprint(get_skills_bp, url_prefix='/api/user')
    app.register_blueprint(get_total_counts_bp, url_prefix='/api/user')
    app.register_blueprint(get_user_networks_bp, url_prefix='/api/user')
    app.register_blueprint(get_users_bp, url_prefix='/api/user')
    app.register_blueprint(login_actions_bp, url_prefix='/api/user')
    app.register_blueprint(register_user_bp, url_prefix='/api/user')
    app.register_blueprint(twitter_login_bp, url_prefix='/api/user')
    app.register_blueprint(write_bp, url_prefix='/api/user')
    app.register_blueprint(device_token_bp, url_prefix='/api/user')
    app.register_blueprint(get_people_bp)  # already has its own routes
    app.register_blueprint(payments_bp) # <-- ADDED
    app.register_blueprint(trigger_summary_bp, url_prefix='/api/user')

    # --- Portal Blueprints ---
    from app.routes.Portal_Routes.Get_Portals import portal_bp as portal_list_bp
    from app.routes.Portal_Routes.Portal_Details import portal_bp as portal_details_bp
    from app.routes.Portal_Routes.Portal_GraphicSections import portal_bp as portal_graphic_sections_bp
    from app.routes.Portal_Routes.Portal_TextSections import portal_bp as portal_texts_bp
    from app.routes.Portal_Routes.SharePortalViaMessage import portal_bp as portal_share_bp
    from app.routes.Portal_Routes.FlagPortal import portal_bp as flag_portal_bp
    from app.routes.Portal_Routes.SearchPortals import search_portals_bp

    app.register_blueprint(search_portals_bp)
    app.register_blueprint(portal_list_bp, url_prefix='/api/portal')
    app.register_blueprint(portal_details_bp, url_prefix='/api/portal')
    app.register_blueprint(portal_graphic_sections_bp, url_prefix='/api/portal')
    app.register_blueprint(portal_texts_bp, url_prefix='/api/portal')
    app.register_blueprint(portal_share_bp, url_prefix='/api/portal')
    app.register_blueprint(flag_portal_bp, url_prefix='/api/portal')

    # --- Messaging Blueprints ---
    from app.routes.Messaging_Routes.DeleteGroupChat import user_bp as delete_group_chat_bp
    from app.routes.Messaging_Routes.DeleteMessage import user_bp as delete_message_bp
    from app.routes.Messaging_Routes.GetGroupChat import group_chat_bp
    from app.routes.Messaging_Routes.GetMessages import user_bp as get_messages_bp
    from app.routes.Messaging_Routes.HideConvo import user_bp as hide_convo_bp
    from app.routes.Messaging_Routes.HideGroupChat import user_bp as hide_group_chat_bp
    from app.routes.Messaging_Routes.ManageChat import user_bp as manage_chat_bp
    from app.routes.Messaging_Routes.SendDirectMessage import user_bp as send_direct_message_bp
    from app.routes.Messaging_Routes.SendGroupChat import user_bp as send_group_chat_bp

    app.register_blueprint(delete_group_chat_bp, url_prefix='/api/message')
    app.register_blueprint(delete_message_bp, url_prefix='/api/message')
    app.register_blueprint(group_chat_bp, url_prefix='/api/message')
    app.register_blueprint(get_messages_bp, url_prefix='/api/message')
    app.register_blueprint(hide_convo_bp, url_prefix='/api/message')
    app.register_blueprint(hide_group_chat_bp, url_prefix='/api/message')
    app.register_blueprint(manage_chat_bp, url_prefix='/api/message')
    app.register_blueprint(send_direct_message_bp, url_prefix='/api/message')
    app.register_blueprint(send_group_chat_bp, url_prefix='/api/message')

    # --- Goal Blueprints ---
    from app.routes.Goals_Routes.GetGoalProgressFeed import goals_bp as get_goal_progress_feed_bp
    from app.routes.Goals_Routes.GetGoalUsers import goals_bp as get_goal_users_bp
    from app.routes.Goals_Routes.Goal_Details import goals_bp as goal_details_bp
    from app.routes.Goals_Routes.Goal_Progress import goals_bp as goal_progress_bp
    from app.routes.Goals_Routes.Goal_Teams import goals_bp as goal_teams_bp
    from app.routes.Goals_Routes.InviteToGoal import goals_bp as invite_to_goal_bp
    from app.routes.Goals_Routes.JoinOrLeaveGoal import goals_bp as join_or_leave_goal_bp
    from app.routes.Goals_Routes.UpdateGoalFilledQuota import goals_bp as update_goal_filled_quota_bp
    from app.routes.Goals_Routes.GetGoals import goals_bp as get_goals_bp

    app.register_blueprint(get_goal_progress_feed_bp, url_prefix='/api/goals')
    app.register_blueprint(get_goal_users_bp, url_prefix='/api/goals')
    app.register_blueprint(goal_details_bp, url_prefix='/api/goals')
    app.register_blueprint(goal_progress_bp, url_prefix='/api/goals')
    app.register_blueprint(goal_teams_bp, url_prefix='/api/goals')
    app.register_blueprint(invite_to_goal_bp, url_prefix='/api/goals')
    app.register_blueprint(join_or_leave_goal_bp, url_prefix='/api/goals')
    app.register_blueprint(update_goal_filled_quota_bp, url_prefix='/api/goals')
    app.register_blueprint(get_goals_bp, url_prefix='/api/goals')

    # --- Public Web Routes (no auth required) ---
    from app.routes.public_web import register_public_routes
    register_public_routes(app)

    # Socket.IO events (import last)
    from . import socket_events

    # Initialize scheduler (only starts if WORKER_MODE=true)
    init_scheduler(app)

    return app