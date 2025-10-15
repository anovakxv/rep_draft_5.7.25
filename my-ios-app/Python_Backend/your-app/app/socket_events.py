# Rep Realtime Socket Events
# Additive changes only (safe). Does NOT alter DB, messaging logic, or FCM push flow.

from flask import request
from flask_socketio import join_room, leave_room, disconnect, emit
from app import socketio, db
import jwt
from config import Config
from app.models.People_Models.Messaging_Models.GroupChatUsers import ChatsUsers

# ---------------- Helpers ---------------- #

def _decode_jwt(token: str):
    try:
        return jwt.decode(token, Config.JWT_SECRET_KEY, algorithms=["HS256"])
    except Exception:
        return None

def _get_socket_token():
    # 1. Try query param (iOS)
    token = request.args.get("token")
    if token:
        return token
    # 2. Try SocketIO v4+ auth object (web)
    if hasattr(request, 'namespace') and hasattr(request.namespace, 'socket'):
        auth = getattr(request.namespace.socket, 'auth', None)
        if auth and isinstance(auth, dict) and 'token' in auth:
            return auth['token']
    # 3. Try Authorization header (web polling fallback)
    auth_header = request.headers.get("Authorization")
    if auth_header and auth_header.startswith("Bearer "):
        return auth_header[7:]
    return None

def _current_user_id():
    token = _get_socket_token()
    payload = _decode_jwt(token) if token else None
    if not payload:
        return None
    return payload.get("sub") or payload.get("user_id")

# ---------------- Core Events ---------------- #

@socketio.on("connect")
def on_connect():
    """
    Validates JWT and automatically joins the user's personal room (user_<id>).
    Supports both iOS (query param) and web (auth object/header).
    """
    token = _get_socket_token()
    payload = _decode_jwt(token) if token else None
    if not token or not payload:
        return False  # reject connection

    uid = payload.get("sub") or payload.get("user_id")
    if not uid:
        return False

    room = f"user_{uid}"
    join_room(room)
    # Acknowledge to the connecting socket only (helps client-side debugging)
    emit("joined_user_room", {"room": room}, room=request.sid)
    # Optional debug:
    # print(f"[Socket] connect sid={request.sid} auto-joined {room}")

@socketio.on("disconnect")
def on_disconnect():
    # Optional: debug
    # print(f"[Socket] disconnect sid={request.sid}")
    pass

# Legacy / generic join (kept for backward compatibility)
@socketio.on("join")
def on_join(data):
    """
    Supports:
      { "room": "user_<id>" }  (personal room)
      { "chat_id": <groupChatId> }  (group chat room)
    """
    uid = _current_user_id()
    if not uid:
        disconnect()
        return

    # Personal user room
    room = (data or {}).get("room")
    if room and room.startswith("user_"):
        numeric = room.replace("user_", "")
        if str(uid) == numeric:
            join_room(room)
            emit("joined_user_room", {"room": room}, room=request.sid)
            # print(f"[Socket] user {uid} joined personal room {room}")
        return  # Do not fall through

    # Group chat join
    chat_id = (data or {}).get("chat_id")
    if not chat_id:
        return
    is_member = db.session.query(ChatsUsers).filter_by(chats_id=chat_id, users_id=uid).count() > 0
    if not is_member:
        return
    room = f"chat_{chat_id}"
    join_room(room)
    emit("joined_room", {"room": room}, room=request.sid)
    # print(f"[Socket] user {uid} joined {room}")

@socketio.on("leave")
def on_leave(data):
    chat_id = (data or {}).get("chat_id")
    if chat_id:
        room = f"chat_{chat_id}"
        leave_room(room)
        emit("left_room", {"room": room}, room=request.sid)
        # print(f"[Socket] left {room}")

# ---------------- Explicit / clearer events (new, additive) ---------------- #

@socketio.on("join_user_room")
def handle_join_user_room(data):
    """
    Client emits: join_user_room { "user_id": <int> }
    We validate against JWT and join user_<id>.
    """
    uid = _current_user_id()
    if not uid:
        disconnect()
        return
    requested = (data or {}).get("user_id")
    if not requested or int(requested) != int(uid):
        return
    room = f"user_{uid}"
    join_room(room)
    emit("joined_user_room", {"room": room}, room=request.sid)
    # print(f"[Socket] user {uid} joined {room}")

@socketio.on("join_group_chat")
def handle_join_group_chat(data):
    """
    Client emits: join_group_chat { "chat_id": <int> }
    Validates membership before joining room chat_<id>.
    """
    uid = _current_user_id()
    if not uid:
        disconnect()
        return
    chat_id = (data or {}).get("chat_id")
    if not chat_id:
        return
    is_member = db.session.query(ChatsUsers).filter_by(chats_id=chat_id, users_id=uid).count() > 0
    if not is_member:
        return
    room = f"chat_{chat_id}"
    join_room(room)
    emit("joined_room", {"room": room}, room=request.sid)
    # print(f"[Socket] user {uid} joined {room} (explicit)")

@socketio.on("leave_group_chat")
def handle_leave_group_chat(data):
    chat_id = (data or {}).get("chat_id")
    if chat_id:
        room = f"chat_{chat_id}"
        leave_room(room)
        emit("left_room", {"room": room}, room=request.sid)
        # print(f"[Socket] left {room} (explicit)")