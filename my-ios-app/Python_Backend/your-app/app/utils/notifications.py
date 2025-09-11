import json
import requests
from google.oauth2 import service_account
from google.auth.transport.requests import Request

def send_fcm_notification(fcm_token, title, body, data=None):
    """
    Send a push notification via Firebase Cloud Messaging (FCM) HTTP v1 API.

    Args:
        fcm_token (str): The recipient's FCM device token.
        title (str): The notification title.
        body (str): The notification body text.
        data (dict, optional): Additional custom data to send with the notification.
    """
    SERVICE_ACCOUNT_FILE = "/etc/secrets/rep-1-704a3-802e8daf00b5.json"  # Path to your Render Secret File
    PROJECT_ID = "rep-1-704a3"  # Replace with your Firebase project ID

    try:
        credentials = service_account.Credentials.from_service_account_file(
            SERVICE_ACCOUNT_FILE,
            scopes=["https://www.googleapis.com/auth/firebase.messaging"]
        )
        credentials.refresh(Request())
        access_token = credentials.token

        # Ensure all data values are strings (required by FCM)
        if data:
            data = {str(k): str(v) for k, v in data.items()}

        message = {
            "message": {
                "token": fcm_token,
                "notification": {
                    "title": title,
                    "body": body
                },
                "data": data or {}
            }
        }

        url = f"https://fcm.googleapis.com/v1/projects/{PROJECT_ID}/messages:send"
        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json; UTF-8",
        }
        print(f"FCM payload: {json.dumps(message)}")  # Debug: print payload
        response = requests.post(url, headers=headers, data=json.dumps(message))
        print("FCM v1 response:", response.status_code, response.text)
    except Exception as e:
        print(f"Error sending FCM notification: {e}")


def should_send_notification(user_id, notif_type):
    """
    Check if a user has enabled notifications for a specific type.
    """
    from app.models.People_Models.user import User
    from app import db

    user = db.session.query(User).filter_by(id=user_id).first()
    if not user:
        return False

    # Default to enabled if settings aren't specified
    if not hasattr(user, 'notification_settings') or not user.notification_settings:
        return True

    settings = user.notification_settings

    # Check master notification toggle
    if not settings.get('pushNotificationsEnabled', True):
        return False

    # Check specific notification type
    if notif_type == 'direct_message' and not settings.get('notifDirectMessages', True):
        return False
    elif notif_type == 'group_message' and not settings.get('notifGroupMessages', True):
        return False
    elif notif_type == 'goal_invite' and not settings.get('notifGoalInvites', True):
        return False

    return True

def send_notification(user_id, notif_type, title, body, data=None):
    """
    Send a notification to a user after checking their preferences.
    """
    from app.models.People_Models.user import User
    from app import db

    # Skip if user has disabled this notification type
    if not should_send_notification(user_id, notif_type):
        print(f"Notification skipped: user {user_id} has disabled {notif_type} notifications")
        return

    # Get user's device token
    user = db.session.query(User).filter_by(id=user_id).first()
    if not user or not user.device_token:
        return

    # Send the actual notification
    send_fcm_notification(user.device_token, title, body, data)
