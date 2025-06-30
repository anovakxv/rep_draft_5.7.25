# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from flask import g, jsonify
from app.models.People_Models.Messaging_Models.GroupChatUsers import GroupChatUsers
from app.models.People_Models.Messaging_Models.Group_Messages import Group_Messages
from app.models.People_Models.user import User
from app.utils.auth import jwt_required

def is_user_in_chat(user_id, chats_id):
    """
    Returns True if the user is a member of the chat, otherwise False.
    """
    return GroupChatUsers.query.filter_by(group_id=chats_id, user_id=user_id).count() > 0

def has_user_read_message(user_id, message_id):
    """
    Returns True if the user has read the message, otherwise False.
    """
    # You may need to adjust this if you have a separate model for message reads
    return Group_Messages.query.filter_by(id=message_id, user_id=user_id, read=True).first() is not None

def get_read_message_ids_for_user(user_id, message_ids):
    """
    Returns a set of message IDs that the user has read from the provided list.
    """
    # Adjust this if you have a separate model for message reads
    rows = Group_Messages.query.filter(
        Group_Messages.user_id == user_id,
        Group_Messages.id.in_(message_ids),
        Group_Messages.read == True
    ).all()
    return set(row.id for row in rows)

def require_login_and_chat_membership(chats_id):
    """
    Checks if the user is logged in and is a member of the chat.
    Returns (user_id, error_response) where error_response is None if checks pass.
    """
    # Use JWT auth context
    user_id = getattr(g, "current_user", None)
    if not user_id or not getattr(g.current_user, "id", None):
        return None, (jsonify({'error': 'login required!'}), 401)

    user_id = g.current_user.id
    is_member = GroupChatUsers.query.filter_by(group_id=chats_id, user_id=user_id).count()
    if not is_member:
        return None, (jsonify({'error': 'permission denied'}), 403)

    return user_id, None

def chat_exists(chats_id):
    """
    Returns True if the chat exists, otherwise False.
    """
    from app.models.People_Models.Messaging_Models.GroupChatMetaData import GroupChatMetaData
    return GroupChatMetaData.query.filter_by(id=chats_id).first() is not None

def user_exists(user_id):
    """
    Returns True if the user exists, otherwise False.
    """
    return User.query.filter_by(id=user_id).first() is not None
