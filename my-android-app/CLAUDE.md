# Rep Android — Claude Code Guide

## ⛔ CRITICAL: DO NOT MODIFY THE BACKEND

The Android app uses the **exact same live production backend** as the iOS and web apps.

**Backend location:** `../my-ios-app/Python_Backend/`
**Backend URL:** `https://rep-june2025.onrender.com`

The backend auto-deploys to Render on every git push. Any backend change affects all three frontends simultaneously. **Never touch Python_Backend/ files to get Android features working.** All the API endpoints you need already exist — check the iOS or web implementation first.

If a feature appears to need a new endpoint, check the CLAUDE.md in the root `my-ios-app/` project first — it almost certainly already exists.

---

## Project Structure

```
my-android-app/
├── app/                        ← Android module (all source code lives here)
│   └── src/main/
│       ├── java/com/networkedcapital/rep/
│       │   └── presentation/   ← UI screens, ViewModels
│       └── res/                ← Layouts, drawables, strings
├── gradle/                     ← Gradle wrapper (committed)
├── build.gradle                ← Root build config
├── settings.gradle.kts         ← Project settings (rootProject.name = "Rep")
└── gradlew / gradlew.bat       ← Gradle wrapper scripts
```

**Android Studio:** Open the project at `my-android-app/` (where `settings.gradle.kts` lives).

---

## Architecture

| Layer | Stack |
|-------|-------|
| Language | Kotlin |
| UI | XML layouts + ViewModels (bring to Jetpack Compose parity with iOS as next step) |
| Networking | Retrofit / OkHttp |
| Auth | JWT stored in SharedPreferences — send as `Bearer {token}` header |
| Images | Glide or Picasso |
| Sockets | Socket.IO Android client |

---

## API Reference

All endpoints are identical to iOS and web. Base URL: `https://rep-june2025.onrender.com`

**Auth pattern** (same as iOS):
```kotlin
request.addHeader("Authorization", "Bearer $jwtToken")
```

**401/403 response** → clear token, redirect to login.

Key endpoints (see iOS `APIConfig.swift` and Python_Backend routes for full list):
- `POST /api/user/login` — returns `{ result, token }`
- `GET /api/user/profile` — user profile
- `GET /api/message/group_chat?chats_id=` — group chat + messages
- `GET /api/active_chat_list` — Chats tab
- `POST /api/message/send_message` — send DM
- `POST /api/message/send_chat_message` — send group message
- `GET /api/goals/details?goals_id=` — goal detail (includes `chats_id` for team chat)
- `POST /api/goals/join_leave` — join or leave a goal team

---

## Key Patterns (match iOS behavior exactly)

- **Image upload:** multipart form-data, JPEG 0.85 compression
- **S3 images:** prefix relative URLs with `https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/`
- **Rep green:** `#8CC65D`
- **Goal Team Chat:** each goal has a canonical `chats_id` — use it to open the team chat directly, never create a new chat for an existing goal
- **Sockets:** join `user_{userId}` room on connect; join `chat_id` room when opening group chat

---

## Current Status

App is feature-complete but needs parity review with iOS before launch:
1. Review each screen against iOS equivalent
2. Ensure Goal Team Chat auto-join flow works (backend handles it — just needs UI wiring)
3. Polish pass

**Do not start new backend work.** Focus only on the Android frontend.
