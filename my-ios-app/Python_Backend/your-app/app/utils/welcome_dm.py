# Rep
# Copyright (c) 2025 Networked Capital Inc. All rights reserved.
# Created by Adam Novak: August 2025

import os
from datetime import datetime

def get_admin_user_id():
    val = os.getenv("ADMIN_USER_ID")
    if not val:
        return None
    try:
        return int(val)
    except Exception:
        return None

def send_welcome_dm_once(db, socketio, recipient_id: int, text: str = "Welcome to Rep! \n\nClicking the Rep logo in the bottom right toggles between Purposes / People. \n\n View the Purpose Pitches in fullscreen by clicking the image at the top of a Purpose page."
"\n\nStart by viewing a Purpose that you'd like to prioritize."
"\n\nThen join a Goal Team! \n\nThank you! "):
    """
    Safely creates one welcome DirectMessage for the recipient if not already present.
    Emits 'direct_message_notification' so iOS shows the OPEN dot instantly.
    Returns True if a new message was created, False otherwise.
    """
    try:
        from app.models.People_Models.Messaging_Models.Direct_Messages import DirectMessage
        from app.models.People_Models.user import User
    except Exception:
        return False

    sender_id = get_admin_user_id()
    if not sender_id or sender_id == recipient_id:
        return False

    # Idempotency: if any prior DM exists from admin -> recipient, skip
    try:
        prior = (DirectMessage.query
                 .filter(DirectMessage.sender_id == sender_id,
                         DirectMessage.recipient_id == recipient_id)
                 .first())
        if prior:
            return False
    except Exception:
        return False

    # Create message
    msg = DirectMessage(
        sender_id=sender_id,
        recipient_id=recipient_id,
        text=text,
        created_at=datetime.utcnow()
    )
    db.session.add(msg)
    try:
        db.session.commit()
    except Exception:
        db.session.rollback()
        return False

    # Emit socket notification (best-effort)
    try:
        sender = User.query.filter_by(id=sender_id).first()
        payload = {
            "type": "direct_message",
            "id": msg.id,
            "message_id": msg.id,
            "sender_id": sender_id,
            "sender_name": (f"{sender.fname or ''} {sender.lname or ''}").strip() if sender else "",
            "recipient_id": recipient_id,
            "text": msg.text,
            "timestamp": msg.created_at.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "read": "0"
        }
        socketio.emit("direct_message_notification", payload, room=f"user_{recipient_id}")
    except Exception:
        pass

    return True