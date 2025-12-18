# Socket.IO Real-Time Messaging Debug Notes

**Date**: December 18, 2025
**Status**: ❌ NOT WORKING - Investigation paused

---

## Problem Summary

Web app socket.io connections are being rejected by the backend. Real-time messaging notifications (like the chat dot indicator) don't appear instantly on web, but work fine on iOS.

**Error**: `Connection rejected by server`

---

## What Works

- ✅ iOS app real-time messaging (uses query param `?token=xyz`)
- ✅ Frontend sends valid JWT token via `auth: { token }` in socket.io Manager config
- ✅ Token is valid, not expired, contains correct user_id
- ✅ User login/profile loading after authentication (fixed separately)

---

## What Doesn't Work

- ❌ Backend receives `auth=None` instead of `{'token': '...'}`
- ❌ Flask-SocketIO is NOT passing client's auth object to connect handler
- ❌ Web app socket connections get rejected

---

## Technical Details

### Frontend (useSocketManager.ts)
```typescript
manager = new Manager(baseURL, {
  auth: { token }, // Sends token in auth object
  extraHeaders: { Authorization: `Bearer ${token}` }, // Fallback for polling
  // ... other config
});
```

### Backend (socket_events.py)
```python
@socketio.on("connect")
def on_connect(auth=None):
    # auth parameter receives None instead of {'token': '...'}
    token = None
    if auth and isinstance(auth, dict) and 'token' in auth:
        token = auth['token']
    else:
        token = _get_socket_token()  # Falls back to query param (iOS method)
```

### Current Logs

**Backend (Render):**
```
[Socket] connect attempt from cBZ0fH4oxiYXntRXAAAh
[Socket] request.args: ImmutableMultiDict([('EIO', '4'), ('transport', 'websocket')])
[Socket] Authorization header: NONE
[Socket] auth parameter: None  ← THE PROBLEM
[Socket] token from _get_socket_token(): NONE...
[Socket] REJECTING - no token or invalid JWT
```

**Frontend (Browser Console):**
```
🔌 (Realtime) Attempting connect for user 123
🔑 (Realtime) Token (first 20 chars): eyJhbGciOiJIUzI1NiIs...
⚠️ (Realtime) Connection Error: Connection rejected by server
```

---

## Root Cause Analysis

The issue is that **Flask-SocketIO is NOT passing the client's `auth` object to the `on_connect()` handler**. Even though:
1. Frontend is correctly sending `auth: { token }` in socket.io client config
2. Backend handler accepts `auth=None` parameter
3. The auth object should theoretically be passed by Flask-SocketIO

**This suggests** that Flask-SocketIO may handle auth differently than the Node.js Socket.IO server, or the auth data is accessible through a different mechanism.

---

## Next Steps to Investigate

### Option 1: Deep Request Inspection (Requires Backend Changes)
Add comprehensive logging to inspect ALL request context attributes to find where auth data actually lives:
```python
@socketio.on("connect")
def on_connect(auth=None):
    print(f"[DEBUG] request.__dict__: {request.__dict__}")
    print(f"[DEBUG] request.environ keys: {request.environ.keys()}")
    print(f"[DEBUG] request.args: {request.args}")
    print(f"[DEBUG] request.headers: {dict(request.headers)}")
    # ... check where auth actually is
```

### Option 2: Use Query Parameter for Web (Simpler, Proven)
Switch web app to use query parameters like iOS does:
- **Frontend**: Change socket connection to pass token as query param `?token=xyz`
- **Backend**: Already supports this via `_get_socket_token()`
- **Benefit**: Known working method, less risk

### Option 3: Research Flask-SocketIO Auth Implementation
- Review Flask-SocketIO documentation for client auth handling
- Check Flask-SocketIO source code to see where auth is stored
- Look for Flask-SocketIO version-specific auth behavior

---

## Files Modified (Safe, Production-Ready)

### Backend: `socket_events.py`
- Added `auth=None` parameter to `on_connect()` (line 51)
- Added debug logging for auth parameter (lines 53-60)
- Added token extraction from auth object with fallback (lines 62-68)
- **Status**: Safe for iOS (uses fallback query param method)

### Frontend: `MainScreen.vue`
- Fixed login bug by reloading localStorage in onMounted (lines 967-969)
- Fixed login bug by reloading localStorage in onActivated (lines 1081-1082)
- Fixed login bug by reloading localStorage in visibilitychange (lines 1060-1061)
- **Status**: Working, fixes user authentication after login

### Frontend: `useSocketManager.ts`
- Added JWT decode debugging (lines 35-49)
- Added extensive connection logging (lines 143-161)
- Sends `auth: { token }` in Manager config (line 114)
- **Status**: Correctly sending auth to server

---

## Important Notes

- **DO NOT modify backend without permission** - this is live production backend
- All current changes are safe and don't break iOS app
- Debug logging can stay or be removed as needed
- iOS real-time messaging continues to work normally

---

## Recommended Next Action

**Use Option 2 (Query Parameter for Web)** - This is the safest and most reliable approach since it's already proven to work with iOS. Would require minimal changes to frontend socket connection code.

---

## Contact Points

- Backend: `Python_Backend/your-app/app/socket_events.py`
- Frontend Socket Manager: `webApp/store/useSocketManager.ts`
- Frontend Main Screen: `webApp/views/MainScreen.vue`
