# new user_utils.py file
# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: June 2025

from app import db
from app.models.People_Models.user import User

def manage_user_row(row, user_id=None, level='1'):
    """
    Enriches a user row dictionary with additional fields as needed.
    You can expand this function to add more computed fields.
    """
    # Example: Add a 'full_name' field
    row['full_name'] = f"{row.get('fname', '')} {row.get('lname', '')}".strip()
    # Example: Hide email if not self or admin
    if level != '0':
        row.pop('email', None)
    return row

def check_user_data(data):
    """
    Checks if required user registration fields are present.
    Raises Exception if any required field is missing.
    """
    required_fields = ['email', 'password']
    for field in required_fields:
        if not data.get(field):
            raise Exception(f"{field} is required!")
    # Optionally check for username, fname, lname, etc.
    return True

def check_new_email(email, current_email=None):
    """
    Checks if the email is unique (unless it's the current user's email).
    Raises Exception if email is already taken.
    """
    if not email:
        raise Exception("Email is required!")
    q = User.query.filter_by(email=email)
    if current_email:
        q = q.filter(User.email != current_email)
    if q.first():
        raise Exception("Email already exists!")
    return True

def check_new_username(username, current_username=None):
    """
    Checks if the username is unique (unless it's the current user's username).
    Raises Exception if username is already taken.
    """
    if not username:
        raise Exception("Username is required!")
    q = User.query.filter_by(username=username)
    if current_username:
        q = q.filter(User.username != current_username)
    if q.first():
        raise Exception("Username already exists!")
    return True

def register_new_activity(user_id, target_id, activity_type, activity_value, object_id, object_type):
    """
    Stub for registering a new activity (e.g., for notifications).
    Implement as needed.
    """
    # Example: Log or insert into an activities table
    pass

def does_user_block(user_id_1, user_id_2):
    """
    Returns True if user_id_1 has blocked user_id_2.
    Replace this stub with your actual block logic.
    """
    # Example: always return False (no blocking)
    return False

def mark_all_activities_as_read(user_id):
    """
    Stub for marking all activities as read for a user.
    Implement as needed.
    """
    pass
