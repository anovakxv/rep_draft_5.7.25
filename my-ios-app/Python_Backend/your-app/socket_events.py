from flask import request
from flask_socketio import join_room, leave_room, disconnect
from app import socketio, db
import jwt
from config import Config
from app.models.People_Models.Messaging_Models.GroupChatUsers import ChatsUsers

def _decode_jwt(token: str):
    try:
        return jwt.decode(token, Config.JWT_SECRET_KEY, algorithms=["HS256"])
    except Exception:
        return None

@socketio.on("connect")
def on_connect():
    token = request.args.get("token")
    if not token or not _decode_jwt(token):
        return False
    # print(f"Socket connect {request.sid}")

@socketio.on("join")
def on_join(data):
    token = request.args.get("token")
    payload = _decode_jwt(token) if token else None
    if not payload:
        disconnect()
        return
    user_id = payload.get("sub") or payload.get("user_id")
    chat_id = data.get("chat_id")
    if not user_id or not chat_id:
        return
    is_member = db.session.query(ChatsUsers).filter_by(chats_id=chat_id, users_id=user_id).count() > 0
    if not is_member:
        return
    join_room(f"chat_{chat_id}")

@socketio.on("leave")
def on_leave(data):
    chat_id = data.get("chat_id")
    if chat_id:
        leave_room(f"chat_{chat_id}")

@socketio.on("disconnect")
def on_disconnect():
    pass

