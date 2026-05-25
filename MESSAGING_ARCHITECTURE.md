# Rep — Live Messaging Architecture

Last updated: 2026-05-25
Status: ✅ Working — iOS, Web mobile, Web desktop

> Historical context: `SOCKET_IO_MESSAGING_DEBUG.md` documents a December 2025 period when
> web socket auth was broken. That issue is resolved. This document reflects current state.

---

## Overview

Rep uses a hybrid approach: REST for sending messages and fetching history, Socket.IO for
real-time notifications. The chat list updates via a two-layer strategy:

1. **Instant local update** — socket event arrives → matching chat moves to top, preview
   text updates immediately. Zero network call. Zero skeleton flash.
2. **Silent background sync** — 300ms later, a full `active_chat_list` API fetch runs to
   reconcile state. No loading skeleton shown if the list already has data.

This replaced the original pattern where every socket event triggered a full fetch with
a loading skeleton, causing a ~500-800ms visual flicker on every incoming message.

---

## Stack

| Layer | Technology |
|-------|-----------|
| Backend real-time | Flask-SocketIO + gevent |
| iOS real-time | `RealtimeSocketManager.shared` (custom singleton, `SocketIO` Swift SDK) |
| Web real-time | `useSocketManager.ts` (custom singleton, `socket.io-client`) |
| Transport | HTTP long-polling → WebSocket upgrade (Render proxy compatibility) |
| Auth | JWT passed as `?token=` query param (iOS) and `auth: { token }` + `Authorization` header (web) |

---

## Room Architecture

```
user_{userId}     — personal room, each user joins on connect
                    receives: DM notifications, group message notifications, invite events

chat_{chatId}     — group chat room, joined when user opens a specific group chat
                    receives: group_message events (real-time in-chat messages)
```

Users join their personal room automatically on socket connect. Chat rooms are joined
explicitly when a user opens a group chat and left when they close it.

---

## Socket Events

### Emitted by backend → received by clients

#### `direct_message_notification`
Sent to `room=user_{recipientId}` when a DM is sent.

```json
{
  "sender_id": 123,
  "recipient_id": 456,
  "text": "Hey!",
  "timestamp": "2026-05-25T14:30:00Z",
  "read": "0"
}
```
**File:** `Python_Backend/your-app/app/routes/Messaging_Routes/SendDirectMessage.py`

---

#### `group_message`
Sent to `room=chat_{chatId}` when a group message is sent.
Only received by clients who have joined that chat room (i.e., currently have the chat open).

```json
{
  "chat_id": 789,
  "id": 1042,
  "sender_id": 123,
  "sender_name": "Adam Novak",
  "sender_photo_url": "https://...",
  "text": "Hey everyone",
  "timestamp": "2026-05-25T14:30:00Z"
}
```
**File:** `Python_Backend/your-app/app/routes/Messaging_Routes/SendGroupChat.py`

---

#### `group_message_notification`
Sent to `room=user_{uid}` for each group member (except sender) when a group message is sent.
Always fires, regardless of whether the recipient has the chat open.

```json
{
  "type": "group_message",
  "chat_id": 789,
  "message_id": 1042,
  "sender_id": 123,
  "text": "Hey everyone",
  "timestamp": "2026-05-25T14:30:00Z"
}
```
**File:** `Python_Backend/your-app/app/routes/Messaging_Routes/SendGroupChat.py`

---

#### `goal_team_invite` / `goal_team_invite_update`
Sent to recipient's personal room for goal team invite actions.
Triggers the OPEN dot and a pending invites refresh. No message preview update needed.

---

### Emitted by clients → received by backend

| Event | When |
|-------|------|
| `join_user_room` | On connect, to join `user_{userId}` room |
| `join` | Legacy fallback (same purpose) |
| `join_group_chat` | When user opens a group chat |
| `leave_group_chat` | When user closes a group chat |

---

## Chat List Data Model

### `ActiveChat` (what `active_chat_list` returns)

```typescript
interface ActiveChat {
  id: string;              // "direct-{contactUserId}" or "group-{chatId}"
  type: 'direct' | 'group';
  user?: User;             // present for direct chats
  chat?: ChatModel;        // present for group chats — { id: number, name?: string }
  last_message?: MessageModel;
  last_message_time?: string;  // ISO 8601
}

interface MessageModel {
  id: number;
  text?: string;
  read?: string;           // "0" = unread, "1" = read
  sender_id?: number;
  created_at?: string;     // ISO 8601
}
```

**Key:** `id` is always `"direct-{userId}"` or `"group-{chatId}"`. The local update
functions use this to find and move the right chat to the top.

**Backend endpoint:** `GET /api/active_chat_list?user_id={id}&limit=200`
**File:** `Python_Backend/your-app/app/routes/User_Routes/Get_People.py`

---

## Chat List Update Flow (Current Implementation)

```
Socket event arrives
        │
        ▼
bumpChatToTop() — O(n) scan of local list
        │
        ├── Chat found → move to position 0, update preview text + timestamp
        │                  → list re-renders instantly (no blank state, no skeleton)
        │
        └── Chat not found → no-op (new conversation, not yet in list)
                │
                ▼
        300ms delay → fetchPeople(0) — background API sync
                        │
                        ├── List non-empty → NO loading skeleton (Option A)
                        │                    silently replaces list data
                        │
                        └── List empty → show loading skeleton (first load only)
```

### What triggers a chat list refresh

| Trigger | Behavior |
|---------|----------|
| Socket: `direct_message_notification` | `bumpChatToTop` → silent background fetch |
| Socket: `group_message` | `bumpChatToTop` → silent background fetch |
| Socket: `group_message_notification` | `bumpChatToTop` → silent background fetch |
| Tab switch to Chats (section 0) | Full fetch, skeleton only if list empty |
| Return from chat view | `refreshActiveChats` DOM event → silent fetch |
| App enters foreground / socket reconnect | Re-fetch if stale |
| After sending a message (desktop inline) | `emit('refresh-chats')` → parent `fetchPeople(0)` |
| First load (list empty) | Full fetch with loading skeleton |

---

## Platform Implementations

### iOS — `MainScreen.swift`

**ViewModel:** `PeopleViewModel` (class, `ObservableObject`)

Key properties:
- `@Published var activeChats: [ActiveChat]` — the source of truth for the list
- `@Published var isLoading: Bool` — controls skeleton display
- `@Published var hasUnreadDirectMessages: Bool` — persisted to UserDefaults
- `@Published var hasUnreadGroupMessages: Bool` — persisted to UserDefaults

Key methods:
- `fetchPeople(userId:section:force:isTabSwitch:)` — entry point, throttles at 0.25s
- `performActiveChatsFetch(userId:force:)` — does the actual URLSession call
- `bumpChatToTop(chatId:text:senderId:timestamp:)` — instant local update

**Loading skeleton logic:**
```swift
// Only shown on first load (empty list) — never on background refreshes
if activeChats.isEmpty {
    isLoading = true
}
```

**Retry logic:** `performActiveChatsFetch` retries once after 2 seconds on network error,
server error (non-2xx), or decode failure. `retryAttemptCount` prevents infinite loops.

**Socket manager:** `RealtimeSocketManager.shared` — singleton with closure-based callbacks.

---

### Web Mobile — `MainScreen.vue`

**Composable:** `usePeople(userId, lastFetchTime)` returns the chat state and functions.

Key refs:
- `activeChats: ref<ActiveChat[]>` — the list
- `isLoading: ref<boolean>` — controls skeleton display
- `hasUnreadDM: ref<boolean>` / `hasUnreadGroup: ref<boolean>` — persisted to localStorage

Key functions:
- `fetchPeople(section)` — fetches chats or people depending on section
- `bumpChatToTop(matcher, lastMsg, timestamp)` — instant local update

**Loading skeleton logic:**
```typescript
// Only shown when list is empty (first load)
if (section !== 0 || activeChats.value.length === 0) {
  isLoading.value = true;
}
```

**Socket manager:** `useSocketManager()` — module-level singleton, shared across components.
Composable pattern means multiple components can subscribe without creating duplicate connections.

---

### Web Desktop — `DesktopDashboard.vue`

The desktop sidebar chat list is owned by `MainScreen.vue` and passed as props
(`activeChats`, `filteredActiveChats`). DesktopDashboard does NOT manage its own chat list.

Desktop-specific concerns:
- **Inline chat pane:** `appendFromSocketIfNeeded(selectedChat)` fetches new messages for the
  currently-open chat when a socket event arrives. Deduplicates by message ID.
- **Send from desktop:** After `sendInlineMessage()` succeeds, `emit('refresh-chats')` tells
  the parent to run `fetchPeople(0)` to update the sidebar preview + ordering.
- **Auto-select:** When `filteredActiveChats` first populates, the first chat is auto-selected
  so the inline pane is never blank on load.

**Desktop socket handlers** only call `appendFromSocketIfNeeded` — sidebar updates come from
MainScreen.vue's own handlers via the shared `useSocketManager` singleton.

---

## Backend — Sending Messages

### Direct messages
`POST /api/message/send_message`
**File:** `Python_Backend/your-app/app/routes/Messaging_Routes/SendDirectMessage.py`

Flow:
1. Validate sender auth (`@jwt_required`)
2. Create `DirectMessage` record, commit to DB
3. Emit `direct_message_notification` to `user_{recipientId}`

### Group messages
`POST /api/message/send_chat_message`
**File:** `Python_Backend/your-app/app/routes/Messaging_Routes/SendGroupChat.py`

Flow:
1. Validate sender auth, verify membership in chat
2. Create `GroupMessage` record, commit to DB
3. Emit `group_message` to `chat_{chatId}` (for members with chat open)
4. Emit `group_message_notification` to each member's personal room (for the OPEN dot)
5. Optionally send FCM push notification (non-fatal if it fails)

Socket emit is wrapped in try/except — a socket failure never blocks the REST response.

---

## Known Patterns and Gotchas

### 1. New conversation case
`bumpChatToTop` does nothing if the chat ID isn't in the list yet (new DM from someone you've
never messaged). The background sync at 300ms adds it. This is intentional — better to add
it slightly delayed than to create a broken local entry.

### 2. Two socket events for every group message
`group_message` (to chat room) AND `group_message_notification` (to personal room) both fire.
On the chat list, both handlers call `bumpChatToTop` with the same data. The second call
is a no-op if the chat is already at position 0 (which it will be after the first). Safe.

### 3. Socket auth — two methods
- **iOS:** token as query param `?token=xyz` — proven, always works
- **Web:** `auth: { token }` + `Authorization: Bearer {token}` header — currently working
- If web auth breaks again (see `SOCKET_IO_MESSAGING_DEBUG.md` for history), fall back to
  query param on the web as well (`extraHeaders` already sends the Authorization header as
  a fallback for polling transport).

### 4. Transport: polling → WebSocket upgrade
Socket.IO is configured `transports: ['polling', 'websocket']` on the web. Starts with
HTTP long-polling (reliable through Render's load balancer/proxy), then upgrades to
WebSocket. Do NOT set `transports: ['websocket']` only — it causes repeated connection
failures on Render.

### 5. Gevent, NOT eventlet
Backend runs gevent workers (`gunicorn -w 1 -k gevent`). Do NOT switch back to eventlet
— Python 3.13 broke eventlet. This also affects S3: always use `put_object()` not
`upload_fileobj()` (eventlet's ThreadPoolExecutor monkey-patching breaks boto3; gevent
has the same risk).

### 6. Single gunicorn worker
Currently `-w 1`. Socket.IO sessions are per-process, so one worker means all connections
share state. When scaled to `-w 2+`, add a Redis instance and set `REDIS_URL` env var —
no code changes needed, `message_queue=os.getenv("REDIS_URL")` is already in `__init__.py`.

### 7. Background fetch message ID placeholder
`bumpChatToTop` creates a `MessageModel` with `id = (old.last_message?.id ?? 0) + 1` as
a placeholder (iOS) or preserves the existing `id` (web). The real `id` arrives with the
background sync. The `ActiveChat.==` check on iOS will detect the difference and re-render
once, but this is invisible since the content is correct from the start.

### 8. Unread dot persistence
`hasUnreadDirectMessages` / `hasUnreadGroupMessages` are persisted to UserDefaults (iOS)
and localStorage (web) so the OPEN dot survives app backgrounding and page refreshes.
They are only cleared when `fetchPeople(0)` returns and finds no unread messages.

---

## Stability Patterns

| Pattern | Where | What it protects |
|---------|-------|-----------------|
| Request cancellation | `PeopleViewModel.currentActiveChatsFetchTask` | Prevents stale responses overwriting fresh data on rapid tab switches |
| 0.25s throttle | `PeopleViewModel.fetchPeople` | Prevents socket bursts (multiple rapid messages) from firing N API calls |
| 300ms delay before sync | All socket handlers | Gives the backend time to commit the message before the list fetch runs |
| Retry once after 2s | `performActiveChatsFetch` | Recovers from transient network errors without infinite loops |
| `isFetching` guard | `performActiveChatsFetch` | Prevents concurrent fetches (force flag overrides for socket events) |
| Socket emit in try/except | `SendDirectMessage.py`, `SendGroupChat.py` | Socket failure never blocks the REST response |
| `appendFromSocketIfNeeded` dedup by ID | `DesktopDashboard.vue` | Prevents duplicate messages in inline chat pane |

---

## Known Remaining Gaps

### List reorder snap (web + iOS)
When a chat jumps from position 3 to position 1, it snaps instantly. No blank state, but
visually abrupt. Fix: wrap list in `<TransitionGroup>` (Vue) or add `.animation(.default)`
on `ForEach` (iOS). Low priority — the core flicker is already eliminated.

### 401/403 not handled in chat views
`Chat_Individual.vue`, `Chat_Group.vue` (web) and `Chat_Individual.swift` (iOS) don't
check HTTP status codes in fetch calls. Auth expiry inside a chat leaves the user with
empty messages instead of redirecting to login. Backend enforces auth correctly — this is
a UX degradation, not a security issue.

### Redis not yet enabled
All socket events are in-process only. Required before scaling to multiple workers.
Action: add a Render Redis instance → set `REDIS_URL` env var. No code changes.

---

## Files Reference

| Purpose | File |
|---------|------|
| Backend socket connect/auth | `Python_Backend/your-app/app/socket_events.py` |
| Send DM + emit socket | `Python_Backend/.../Messaging_Routes/SendDirectMessage.py` |
| Send group msg + emit socket | `Python_Backend/.../Messaging_Routes/SendGroupChat.py` |
| Chat list API endpoint | `Python_Backend/.../User_Routes/Get_People.py` (`api_active_chat_list`) |
| Web socket singleton | `web-app/src/pages/utils/useSocketManager.ts` |
| Web chat list (mobile) | `web-app/src/pages/MainPages/MainScreen.vue` (`usePeople`, socket handlers) |
| Web chat list (desktop) | `web-app/src/pages/MainPages/DesktopDashboard.vue` (`appendFromSocketIfNeeded`) |
| iOS socket singleton | `my-ios-app/Swift FrontEnd/Rep/RealtimeSocketManager.swift` |
| iOS chat list + ViewModel | `my-ios-app/Swift FrontEnd/Rep/MainScreen.swift` (`PeopleViewModel`) |
