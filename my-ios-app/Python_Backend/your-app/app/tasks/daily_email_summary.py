# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: January 2025

"""
Daily email summary task - sends users a digest of messages received in last 24 hours
"""

import os
from datetime import datetime, timedelta
from jinja2 import Template
from app import db
from app.models.People_Models.user import User
from app.models.People_Models.Messaging_Models.Direct_Messages import DirectMessage
from app.models.People_Models.Messaging_Models.Group_Messages import GroupMessage
from app.models.People_Models.Messaging_Models.GroupChatMetaData import Chats
from app.models.People_Models.Messaging_Models.GroupChatUsers import ChatsUsers
from app.utils.mail_utils import send_mail


# ========================
# Query Functions
# ========================

def get_users_with_email_preference():
    """
    Get all users who should receive daily email summaries.

    Currently returns all users with email addresses.
    Future: Check user.notification_settings JSON for preferences.

    Returns:
        List[User]: Users who want daily summaries
    """
    return User.query.filter(
        User.email.isnot(None),
        User.email != ''
    ).all()


def get_direct_messages_for_user(user_id, hours=24):
    """
    Fetch direct messages received by user in the last X hours.

    Args:
        user_id (int): User ID
        hours (int): Number of hours to look back (default 24)

    Returns:
        List[DirectMessage]: Messages received by the user
    """
    cutoff = datetime.utcnow() - timedelta(hours=hours)

    return DirectMessage.query.filter(
        DirectMessage.recipient_id == user_id,
        DirectMessage.created_at >= cutoff
    ).order_by(DirectMessage.created_at.desc()).all()


def get_group_messages_for_user(user_id, hours=24):
    """
    Fetch group messages from user's groups in the last X hours.
    Excludes messages sent by the user themselves.

    Args:
        user_id (int): User ID
        hours (int): Number of hours to look back (default 24)

    Returns:
        List[GroupMessage]: Messages from user's groups
    """
    cutoff = datetime.utcnow() - timedelta(hours=hours)

    # Get user's group IDs
    user_groups = db.session.query(ChatsUsers.chats_id)\
        .filter(ChatsUsers.users_id == user_id).all()

    group_ids = [g[0] for g in user_groups]

    if not group_ids:
        return []

    # Get messages from those groups (excluding own messages)
    return GroupMessage.query.join(Chats)\
        .filter(
            GroupMessage.chat_id.in_(group_ids),
            GroupMessage.sender_id != user_id,  # Don't include user's own messages
            GroupMessage.created_at >= cutoff
        ).order_by(GroupMessage.created_at.desc()).all()


def should_send_summary_to_user(user, dm_count, group_msg_count):
    """
    Determine if we should send an email summary to this user.

    Business logic:
    - Skip if no messages
    - Future: Check user.notification_settings preferences

    Args:
        user (User): User object
        dm_count (int): Number of direct messages
        group_msg_count (int): Number of group messages

    Returns:
        bool: True if should send email
    """
    # Skip if no messages
    if dm_count == 0 and group_msg_count == 0:
        return False

    # Future enhancement: Check user preferences
    # if user.notification_settings:
    #     settings = user.notification_settings
    #     if not settings.get('daily_email_summary', True):
    #         return False

    return True


# ========================
# Helper Functions
# ========================

def truncate_text(text, max_length=100):
    """
    Truncate text for email preview.

    Args:
        text (str): Full text
        max_length (int): Maximum length (default 100)

    Returns:
        str: Truncated text with ellipsis if needed
    """
    if not text:
        return ""

    if len(text) <= max_length:
        return text

    return text[:max_length].rstrip() + "..."


def time_ago(dt):
    """
    Convert datetime to human-readable relative time.

    Args:
        dt (datetime): Datetime object

    Returns:
        str: Human-readable time (e.g., "2 hours ago", "1 day ago")
    """
    if not dt:
        return ""

    delta = datetime.utcnow() - dt

    if delta.seconds < 60:
        return "just now"
    elif delta.seconds < 3600:
        minutes = delta.seconds // 60
        return f"{minutes} min ago" if minutes == 1 else f"{minutes} mins ago"
    elif delta.seconds < 86400 and delta.days == 0:
        hours = delta.seconds // 3600
        return f"{hours} hour ago" if hours == 1 else f"{hours} hours ago"
    elif delta.days == 1:
        return "1 day ago"
    else:
        return f"{delta.days} days ago"


# ========================
# Email Building
# ========================

def build_email_html(user, dms, group_msgs):
    """
    Generate HTML email from template.

    Args:
        user (User): User object
        dms (List[DirectMessage]): Direct messages
        group_msgs (List[GroupMessage]): Group messages

    Returns:
        str: Rendered HTML email
    """
    template_path = os.path.join(
        os.path.dirname(__file__),
        'email_templates',
        'daily_summary.html'
    )

    with open(template_path, 'r', encoding='utf-8') as f:
        template_str = f.read()

    template = Template(template_str)

    # Prepare direct messages data (limit to 10 most recent)
    dm_data = []
    for dm in dms[:10]:
        sender_name = f"{dm.sender.fname or ''} {dm.sender.lname or ''}".strip()
        if not sender_name:
            sender_name = dm.sender.username or "Someone"

        dm_data.append({
            'sender_name': sender_name,
            'text_preview': truncate_text(dm.text, 100),
            'time_ago': time_ago(dm.created_at)
        })

    # Prepare group messages data (limit to 15 most recent)
    group_data = []
    for gm in group_msgs[:15]:
        sender_name = f"{gm.sender.fname or ''} {gm.sender.lname or ''}".strip()
        if not sender_name:
            sender_name = gm.sender.username or "Someone"

        group_data.append({
            'group_name': gm.chat.name if gm.chat else "Unknown Group",
            'sender_name': sender_name,
            'text_preview': truncate_text(gm.text, 100),
            'time_ago': time_ago(gm.created_at)
        })

    # Render template
    html = template.render(
        user_fname=user.fname or 'there',
        dm_count=len(dms),
        group_msg_count=len(group_msgs),
        direct_messages=dm_data,
        group_messages=group_data,
        unsubscribe_url="https://www.repsomething.com/settings"
    )

    return html


# ========================
# Main Task Function
# ========================

def send_daily_summary():
    """
    Main function to send daily email summaries to all users.

    This function:
    1. Fetches all users who want email summaries
    2. For each user, queries their messages from last 24 hours
    3. Builds and sends HTML email via SendGrid
    4. Logs results

    Called by scheduler (app/scheduler.py) once daily.
    """
    print(f"[DailySummary] Starting daily email job at {datetime.utcnow().isoformat()}")

    users = get_users_with_email_preference()
    print(f"[DailySummary] Found {len(users)} users with email addresses")

    sent_count = 0
    skipped_count = 0
    error_count = 0

    for user in users:
        try:
            # Fetch messages for this user
            dms = get_direct_messages_for_user(user.id, hours=24)
            group_msgs = get_group_messages_for_user(user.id, hours=24)

            # Check if should send email to this user
            if not should_send_summary_to_user(user, len(dms), len(group_msgs)):
                skipped_count += 1
                print(f"[DailySummary] Skipped user {user.id} ({user.email}) - no messages")
                continue

            # Build HTML email
            html_content = build_email_html(user, dms, group_msgs)

            # Prepare subject line
            total_messages = len(dms) + len(group_msgs)
            subject = f"Your Daily Rep Summary ({total_messages} new message"
            subject += "s" if total_messages != 1 else ""
            subject += ")"

            # Send via SendGrid
            success = send_mail(
                to=user.email,
                subject=subject,
                body=html_content,
                from_email='contact@repsomething.com'
            )

            if success:
                sent_count += 1
                print(f"[DailySummary] ✓ Sent to user {user.id} ({user.email}) - {len(dms)} DMs, {len(group_msgs)} group msgs")
            else:
                error_count += 1
                print(f"[DailySummary] ✗ Failed to send to user {user.id} ({user.email})")

        except Exception as e:
            error_count += 1
            print(f"[DailySummary] ✗ Error processing user {user.id}: {e}")
            continue

    # Log summary
    print(f"[DailySummary] Complete at {datetime.utcnow().isoformat()}")
    print(f"[DailySummary] Results: Sent={sent_count}, Skipped={skipped_count}, Errors={error_count}")

    return {
        'sent': sent_count,
        'skipped': skipped_count,
        'errors': error_count,
        'total_users': len(users)
    }
