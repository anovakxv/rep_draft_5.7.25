# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import Blueprint, request, jsonify, g
from app import db
from app.models.Purpose_Models.Portal import Portal
# from app.models.users_hidden_portals import UsersHiddenPortals
from app.models.ValueMetric_Models.Goal import Goal
from app.models.ValueMetric_Models.GoalTeam import GoalTeam
from app.models.Purpose_Models.PortalUser import PortalUser
from app.models.Purpose_Models.PortalsUsersShare import PortalsUsersShare
from app.models.Purpose_Models.PortalGraphicSection import PortalGraphicSection
from app.models.Purpose_Models.FlaggedPortal import FlaggedPortal

from sqlalchemy import or_
from sqlalchemy.orm import subqueryload
from app.utils.auth import jwt_required

# --- S3 BASE URL ---
S3_BASE_URL = "https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/"

def patch_main_image_url(portal_dict):
    """
    Ensures mainImageUrl is a full S3 URL or None.
    """
    url = portal_dict.get('mainImageUrl')
    if url and not url.startswith("http"):
        portal_dict['mainImageUrl'] = S3_BASE_URL + url
    if not url or str(url).strip() == "":
        portal_dict['mainImageUrl'] = None
    return portal_dict

portal_bp = Blueprint('portal_list', __name__)

# --- Existing API for ProfileView "Rep" tab ---
@portal_bp.route('/portals', methods=['GET'])
@jwt_required
def api_get_portals():
    """
    Returns a list of portals for the user, each including mainImageUrl for use in portal cards.
    Used for the 'Rep' tab on the ProfileView page.
    """
    args = request.args
    offset = int(args.get('offset', 0))
    limit = int(args.get('limit', 50))
    users_id = args.get('users_id')
    home = args.get('home')
    my_network = args.get('my_network')
    show_hidden = args.get('show_hidden', '1')
    keyword = args.get('keyword', '')
    cities_id = args.get('cities_id')
    portals_id = args.get('portals_id')
    user_id = args.get('user_id')
    shared = args.get('shared', '0')

    # Use JWT user if not provided
    if not user_id and hasattr(g, "current_user"):
        user_id = g.current_user.id

    if offset < 0:
        return jsonify({'error': 'offset is wrong!'}), 400
    if limit > 4096:
        return jsonify({'error': 'limit should be <= 4096'}), 400

    query = Portal.query.options(
        subqueryload(Portal.graphic_sections)
    )

    # Shared logic
    if shared == "1":
        if not users_id:
            return jsonify({'error': 'users_id is empty!'}), 400
        query = query.join(
            PortalsUsersShare, PortalsUsersShare.portals_id == Portal.id
        ).filter(
            PortalsUsersShare.users_id == users_id
        )
    # Home logic: user created or in goal
    elif home == "1":
        if not users_id and not user_id:
            return jsonify({'error': 'Login or users_id required!'}), 400
        uid = users_id or user_id
        subquery = db.session.query(Goal.portals_id).join(
            GoalTeam, Goal.id == GoalTeam.goals_id
        ).filter(GoalTeam.users_id2 == uid)
        query = query.filter(or_(Portal.users_id == uid, Portal.id.in_(subquery)))
    elif users_id:
        query = query.filter(Portal.users_id == users_id)

    # Exclude hidden portals (feature disabled)
    # if show_hidden != "1" and not portals_id and (user_id or users_id):
    #     uid = user_id or users_id
    #     query = query.filter(~Portal.id.in_(
    #         db.session.query(UsersHiddenPortals.portals_id).filter_by(users_id=uid)
    #     ))

    # Keyword search
    if keyword:
        query = query.filter(Portal.name.ilike(f"%{keyword.lower()}%"))

    if cities_id:
        query = query.filter(Portal.cities_id == cities_id)
    if portals_id:
        query = query.filter(Portal.id == portals_id)

    # Network logic
    if my_network:
        if not user_id:
            return jsonify({'error': 'Login required when my_network is not null!'}), 400
        from app.models.People_Models.UserNetwork import UserNetwork
        network_user_ids = db.session.query(UserNetwork.users_id2).filter_by(users_id1=user_id)
        shared_portal_ids = db.session.query(PortalsUsersShare.portals_id).filter(
            PortalsUsersShare.users_id.in_(network_user_ids)
        )
        if my_network == "1":
            query = query.filter(or_(
                Portal.users_id.in_(network_user_ids),
                Portal.id.in_(shared_portal_ids)
            ))
        else:
            query = query.filter(~Portal.users_id.in_(network_user_ids), ~Portal.id.in_(shared_portal_ids))

    # Order and paginate
    if shared == "1":
        query = query.order_by(PortalsUsersShare.id.desc())
    else:
        query = query.order_by(Portal.lead_user_count.desc())

    portals = query.offset(offset).limit(limit).all()
    result = [patch_main_image_url(portal.as_card_dict()) for portal in portals]
    return jsonify({'result': result})

# --- New API for MainScreen filtering tabs ---
@portal_bp.route('/filter_network_portals', methods=['GET'])
@jwt_required
def filter_network_portals():
    """
    Returns a list of portals for the MainScreen, filtered by tab: open, ntwk, all.
    Use ?user_id=...&tab=open|ntwk|all&safe_only=true|false
    """
    args = request.args
    offset = int(args.get('offset', 0))
    limit = int(args.get('limit', 50))
    user_id = args.get('user_id')
    tab = args.get('tab', 'open')  # 'open', 'ntwk', 'all'
    keyword = args.get('keyword', '')
    cities_id = args.get('cities_id')
    portals_id = args.get('portals_id')
    safe_only = args.get('safe_only', 'false').lower() == 'true'

    # Use JWT user if not provided
    if not user_id and hasattr(g, "current_user"):
        user_id = g.current_user.id

    if offset < 0:
        return jsonify({'error': 'offset is wrong!'}), 400
    if limit > 4096:
        return jsonify({'error': 'limit should be <= 4096'}), 400
    if not user_id:
        return jsonify({'error': 'user_id required!'}), 400

    query = Portal.query.options(
        subqueryload(Portal.graphic_sections)
    )

    if tab == "open":
        # OPEN tab = portals where user is creator, a lead, or on a goal team for the portal
        lead_portal_ids = db.session.query(PortalUser.portal_id).filter(
            PortalUser.user_id == user_id,
            PortalUser.role == 'lead'
        )
        goal_team_portal_ids = db.session.query(Goal.portals_id).join(
            GoalTeam, Goal.id == GoalTeam.goals_id
        ).filter(GoalTeam.users_id2 == user_id)
        query = query.filter(
            or_(
                Portal.users_id == user_id,
                Portal.id.in_(lead_portal_ids),
                Portal.id.in_(goal_team_portal_ids)
            )
        )
    elif tab == "ntwk":
        # NTWK tab = all portals where a member of my network is on a GoalTeam
        from app.models.People_Models.UserNetwork import UserNetwork
        network_user_ids = db.session.query(UserNetwork.users_id2).filter_by(users_id1=user_id)
        network_goal_portal_ids = db.session.query(Goal.portals_id).join(
            GoalTeam, Goal.id == GoalTeam.goals_id
        ).filter(GoalTeam.users_id2.in_(network_user_ids))
        query = query.filter(Portal.id.in_(network_goal_portal_ids))
    elif tab == "all":
        # ALL tab = all visible portals
        query = query.filter(Portal.visible == True)
    else:
        return jsonify({'error': 'Invalid tab value!'}), 400

    if safe_only:
        flagged_portal_ids = db.session.query(FlaggedPortal.portal_id).distinct()
        query = query.filter(~Portal.id.in_(flagged_portal_ids))

    if keyword:
        query = query.filter(Portal.name.ilike(f"%{keyword.lower()}%"))
    if cities_id:
        query = query.filter(Portal.cities_id == cities_id)
    if portals_id:
        query = query.filter(Portal.id == portals_id)

    query = query.order_by(Portal.lead_user_count.desc())
    portals = query.offset(offset).limit(limit).all()
    result = [patch_main_image_url(portal.as_card_dict()) for portal in portals]
    return jsonify({'result': result})