# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from app.models.Purpose_Models.Portal import Portal
from app.models.Purpose_Models.PortalUser import PortalUser

def check_portal_editor_permission(user_id, portal_id):
    """
    Returns True if the user is the owner or a leader of the portal, else False.
    """
    # Check if user is the owner
    portal = Portal.query.filter_by(id=portal_id).first()
    if not portal:
        return False
    if portal.users_id == user_id:
        return True

    # Check if user is a leader in PortalUser
    leader = PortalUser.query.filter_by(
        users_id=user_id,
        portals_id=portal_id,
        leader=True
    ).first()
    if leader:
        return True

    return False
