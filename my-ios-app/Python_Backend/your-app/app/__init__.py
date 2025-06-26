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

    # --- Register API Blueprints ---
    from app.routes.api import api_bp
    app.register_blueprint(api_bp)

    # --- Register User API Blueprints (each with a unique alias) ---
    from app.routes.User_Routes.AddToNetwork import user_bp as add_to_network_bp
    from app.routes.User_Routes.BlockUser import user_bp as block_user_bp
    from app.routes.User_Routes.EditUser import user_bp as edit_user_bp
    from app.routes.User_Routes.Get_Me import user_bp as get_me_bp
    from app.routes.User_Routes.Get_Profile import user_bp as get_profile_bp
    from app.routes.User_Routes.GetSkills import user_bp as get_skills_bp
    from app.routes.User_Routes.GetTotalCounts import user_bp as get_total_counts_bp
    from app.routes.User_Routes.GetUserNetworks import user_bp as get_user_networks_bp
    from app.routes.User_Routes.GetUsers import user_bp as get_users_bp
    from app.routes.User_Routes.LoginActions import user_bp as login_actions_bp
    from app.routes.User_Routes.MembersofMyNetwork import user_bp as members_of_my_network_bp
    from app.routes.User_Routes.RegisterUser import user_bp as register_user_bp
    from app.routes.User_Routes.TwitterLogin import user_bp as twitter_login_bp
    from app.routes.User_Routes.Write import user_bp as write_bp

    # This one uses a different blueprint name:
    from app.routes.User_Routes.Get_People import people_bp as get_people_bp

    # Register each blueprint, all under /api/user except Get_People (which has its own endpoints)
    app.register_blueprint(add_to_network_bp, url_prefix='/api/user')
    app.register_blueprint(block_user_bp, url_prefix='/api/user')
    app.register_blueprint(edit_user_bp, url_prefix='/api/user')
    app.register_blueprint(get_me_bp, url_prefix='/api/user')
    app.register_blueprint(get_profile_bp, url_prefix='/api/user')
    app.register_blueprint(get_skills_bp, url_prefix='/api/user')
    app.register_blueprint(get_total_counts_bp, url_prefix='/api/user')
    app.register_blueprint(get_user_networks_bp, url_prefix='/api/user')
    app.register_blueprint(get_users_bp, url_prefix='/api/user')
    app.register_blueprint(login_actions_bp, url_prefix='/api/user')
    app.register_blueprint(members_of_my_network_bp, url_prefix='/api/user')
    app.register_blueprint(register_user_bp, url_prefix='/api/user')
    app.register_blueprint(twitter_login_bp, url_prefix='/api/user')
    app.register_blueprint(write_bp, url_prefix='/api/user')

    # Get_People endpoints (like /api/active_chat_list, /api/filter_people)
    app.register_blueprint(get_people_bp)

    # --- Register Portal API Blueprints ---
    from app.routes.Portal_Routes.Get_Portals import portal_bp as portal_list_bp
    from app.routes.Portal_Routes.Portal_Details import portal_bp as portal_details_bp
    from app.routes.Portal_Routes.Portal_GraphicSections import portal_bp as portal_graphic_sections_bp
    from app.routes.Portal_Routes.Portal_TextSections import portal_bp as portal_texts_bp
    from app.routes.Portal_Routes.SharePortalViaMessage import portal_bp as portal_share_bp

    app.register_blueprint(portal_list_bp)
    app.register_blueprint(portal_details_bp)
    app.register_blueprint(portal_graphic_sections_bp)
    app.register_blueprint(portal_texts_bp)
    app.register_blueprint(portal_share_bp)

    # --- Register Messaging API Blueprints ---
    from app.routes.Messaging_Routes.DeleteGroupChat import user_bp as delete_group_chat_bp
    from app.routes.Messaging_Routes.DeleteMessage import user_bp as delete_message_bp
    from app.routes.Messaging_Routes.GetGroupChat import group_chat_bp
    from app.routes.Messaging_Routes.GetMessages import user_bp as get_messages_bp
    from app.routes.Messaging_Routes.HideConvo import user_bp as hide_convo_bp
    from app.routes.Messaging_Routes.HideGroupChat import user_bp as hide_group_chat_bp
    from app.routes.Messaging_Routes.ManageChat import user_bp as manage_chat_bp
    from app.routes.Messaging_Routes.SendDirectMessage import user_bp as send_direct_message_bp
    from app.routes.Messaging_Routes.SendGroupChat import user_bp as send_group_chat_bp

    app.register_blueprint(delete_group_chat_bp)
    app.register_blueprint(delete_message_bp)
    app.register_blueprint(group_chat_bp)
    app.register_blueprint(get_messages_bp)
    app.register_blueprint(hide_convo_bp)
    app.register_blueprint(hide_group_chat_bp)
    app.register_blueprint(manage_chat_bp)
    app.register_blueprint(send_direct_message_bp)
    app.register_blueprint(send_group_chat_bp)

    # --- Register Goal API Blueprints ---
    from app.routes.Goals_Routes.GetGoalProgressFeed import goals_bp as get_goal_progress_feed_bp
    from app.routes.Goals_Routes.GetGoalUsers import goals_bp as get_goal_users_bp
    from app.routes.Goals_Routes.Goal_Details import goals_bp as goal_details_bp
    from app.routes.Goals_Routes.Goal_Progress import goals_bp as goal_progress_bp
    from app.routes.Goals_Routes.Goal_Teams import goals_bp as goal_teams_bp
    from app.routes.Goals_Routes.InviteToGoal import goals_bp as invite_to_goal_bp
    from app.routes.Goals_Routes.JoinOrLeaveGoal import goals_bp as join_or_leave_goal_bp
    from app.routes.Goals_Routes.UpdateGoalFilledQuota import goals_bp as update_goal_filled_quota_bp
    from app.routes.Goals_Routes.GetGoals import goals_bp as get_goals_bp  

    app.register_blueprint(get_goal_progress_feed_bp)
    app.register_blueprint(get_goal_users_bp)
    app.register_blueprint(goal_details_bp)
    app.register_blueprint(goal_progress_bp)
    app.register_blueprint(goal_teams_bp)
    app.register_blueprint(invite_to_goal_bp)
    app.register_blueprint(join_or_leave_goal_bp)
    app.register_blueprint(update_goal_filled_quota_bp)
    app.register_blueprint(get_goals_bp)

    return app
