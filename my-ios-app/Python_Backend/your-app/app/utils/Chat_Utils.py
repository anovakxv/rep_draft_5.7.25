

from app.models.chats_users import ChatsUsers

def is_user_in_chat(user_id, chats_id):
    """
    Returns True if the user is a member of the chat, otherwise False.
    """
    return ChatsUsers.query.filter_by(chats_id=chats_id, users_id=user_id).count() > 0


from app.utils.chat_utils import is_user_in_chat

# ... inside your route ...
if not is_user_in_chat(user_id, chats_id):
    return jsonify({'error': 'permission denied'}),


from app.models.messages_read import MessagesRead

def has_user_read_message(user_id, message_id):
    """
    Returns True if the user has read the message, otherwise False.
    """
    return MessagesRead.query.filter_by(users_id=user_id, messages_id=message_id).first() is not None

def get_read_message_ids_for_user(user_id, message_ids):
    """
    Returns a set of message IDs that the user has read from the provided list.
    """
    rows = MessagesRead.query.filter(
        MessagesRead.users_id == user_id,
        MessagesRead.messages_id.in_(message_ids)
    ).all()
    return set(row.messages_id for row in
               
from flask import session, jsonify
from app.models.chats_users import ChatsUsers


def require_login_and_chat_membership(chats_id):
    """
    Checks if the user is logged in and is a member of the chat.
    Returns (user_id, error_response) where error_response is None if checks pass.
    """
    user_id = session.get('user_id')
    if not user_id:
        return None, jsonify({'error': 'login required!'}), 401

    is_member = ChatsUsers.query.filter_by(chats_id=chats_id, users_id=user_id).count()
    if not is_member:
        return None, jsonify({'error': 'permission denied'}), 403

    return user_id, None

# Usage example in a route:
# user_id, error = require_login_and_chat_membership(chats_id)
# if error:


from app.models.chats import Chats
from app.models.user import User

def chat_exists(chats_id):
    """
    Returns True if the chat exists, otherwise False.
    """
    return Chats.query.filter_by(id=chats_id).first() is not None

def user_exists(user_id):
    """
    Returns True if the user exists, otherwise False.
    """
    return User.query.filter_by(id=user_id).first() is not None
