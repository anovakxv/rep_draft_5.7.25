# Rep — Claude Code Guide

## Product Mission
**Purpose-driven rolodex.** Rep connects people to relevant purposes, communities, and opportunities to accelerate measurable impact (career growth, community causes, mentorship, etc.).

**North Star (Stage 2):** A new user opens Rep, says "I want to help depolarize politics in Boise," and within 60 seconds is matched to Braver Angels, introduced to 3 local bridge-builders, and invited to join a Goal Team with an AI-optimized workflow.

---

## For Collaborators

**Staging environment** (safe playground — isolated DB, can't touch prod data):
- Web: `https://rep-staging-vercel.vercel.app` — register a fresh account to test
- Backend: `https://rep-staging-backend.onrender.com`
- Staging deploys automatically from the `staging` branch

**Workflow:** branch off `Adam_July2025` → build your feature → open a PR → Adam reviews → merge to `staging` to test → Adam promotes to prod. Read `CONTRIBUTING.md` for the full workflow.

**Safe to work on freely:** anything in `web-app/` — every PR gets a Vercel preview link automatically.

**Requires Adam's review (auto-gated via CODEOWNERS):** `Python_Backend/`, DB migrations, iOS core files (`RepApp.swift`, `MainScreen.swift`), config files (`Procfile`, `requirements.txt`, `package.json`, `vercel.json`).

**Never run `flask db upgrade` on prod** — Adam only, after careful review per `DB_MIGRATION_WORKFLOW.md`.

---

## ⚠️ Critical Rules

- **Backend is LIVE production.** Auto-deploys to Render on push to `Adam_July2025`. Always confirm backend changes with Adam before touching `Python_Backend/`.
- **Never modify `RepApp.swift` or `MainScreen.swift`** without explicit instruction — these are app entry point and tab navigation.
- **DB migrations:** After pushing backend model changes, `flask db upgrade` must be run manually on the Render shell. See `DB_MIGRATION_WORKFLOW.md`. Current prod head: `f6a7b8c9d0e1`.
- **Never deploy on Friday evenings** — no weekend monitoring coverage.
- **Android shares the same backend** — `my-android-app/` is a frontend only. Never modify `Python_Backend/` for Android work.
- **S3 uploads:** always `put_object(Body=file.read())` — **never** `upload_fileobj()` (eventlet breaks boto3's ThreadPoolExecutor).

---

## Architecture

| Layer | Stack |
|-------|-------|
| iOS | SwiftUI + MVVM, `@StateObject` ViewModels, `URLSession`, Kingfisher (images) |
| Web | Vue 3 + Composition API (`<script setup lang="ts">`), Tailwind CSS, Axios |
| Backend | Flask + SQLAlchemy + Alembic, hosted on Render, gunicorn + eventlet |
| DB | PostgreSQL (Render) |
| Storage | S3 bucket `rep-app-dbbucket` (us-west-2) |
| Auth | JWT — `@AppStorage("jwtToken")` iOS / `localStorage` web. 401/403 → clear token, redirect login |
| Email | Resend (`RESEND_API_KEY` env var), from `contact@repsomething.com` |
| Sockets | Flask-SocketIO, `async_mode="gevent"`, `GeventWebSocketWorker` in Procfile |
| Payments | Stripe — checkout sessions + Stripe Connect for portal payouts |

**Production URLs:**
- Backend: `https://rep-june2025.onrender.com`
- Web: `https://repsomething.com`

---

## Repo Structure

```
my-ios-app/                    ← repo root
  Python_Backend/your-app/     ← Flask backend (all backend work happens here)
    app/
      __init__.py              ← app factory, blueprint registration, CORS, limiter
      routes/
        User_Routes/           ← auth, profile, skills, payments, photos, writes
        Portal_Routes/         ← portal CRUD, sections, images, search
        Goals_Routes/          ← goal CRUD, teams, progress, invites
        Messaging_Routes/      ← DMs, group chat, reactions, edits
        public_web/            ← unauthenticated routes (public portal/goal views, contact, payments)
      models/
        People_Models/         ← User, UserType, Skill, UserSkill, messaging models
        Purpose_Models/        ← Portal, PortalGraphicSection, PortalEvent, etc.
        ValueMetric_Models/    ← Goal, GoalTeam, GoalType, ReportingIncrement, Transaction
        s3Content_Models/      ← S3Content (image metadata + ordering)
      utils/
        auth.py                ← @jwt_required decorator
        mail_utils.py          ← Resend email helper
        welcome_dm.py          ← send_welcome_dm_once(), send_founder_dm_once() (user 45 = Adam)
    migrations/versions/       ← Alembic migration files — never edit manually
    wsgi.py                    ← gunicorn entry point (gevent monkey-patches here)
    Procfile                   ← gunicorn --worker-class geventwebsocket... -w 1 wsgi:app

  web-app/src/
    pages/
      MainPages/               ← MainScreen, PortalPage, Edit_Portal, PayTransaction
      RepProfile/              ← ProfileView, EditProfile, LoginView, OnboardingView, UserPhotos, Settings
      GoalPages/               ← GoalsDetailView, EditGoal, InviteTeamSheet, Update_Goal
      Messaging/               ← Chat_Individual, Chat_Group, ChatWrapper, NewGroupChat
      CustomPortals/           ← Portal93Page (custom one-off portal)
      utils/
        api.ts                 ← axios instance with auth interceptor — always use this
        useSocketManager.ts    ← Socket.IO client manager
        socket-bridge.ts       ← event bridge between socket and Vue
    components/                ← MessageBubble, WritingToolbar, EmojiPicker, DateSeparator, etc.

  Swift FrontEnd/Rep/          ← iOS SwiftUI app
    RepApp.swift               ← ⛔ app entry point — do not touch
    MainScreen.swift           ← ⛔ tab navigation — do not touch
    APIConfig.swift            ← baseURL constant
    Components.swift           ← AuthSession, GrowingTextEditor, SafariWebView
    PortalPage.swift           ← Portal detail + PortalViewModel + all portal models
    ProfileView.swift          ← User model, ProfileViewModel, WriteBlock model
    Edit_Portal.swift          ← portal editing + image upload (off-main-thread)

  my-android-app/              ← Android frontend only (shares same backend, never modify Python_Backend for this)
```

---

## Key Patterns

### Web (Vue 3)
- **API calls:** `api.get/post/put/delete()` — always use the axios instance from `@/pages/utils/api`. Never use raw `fetch` or `axios` directly.
- **Auth:** JWT stored in `localStorage`. The `api` instance attaches `Bearer {token}` automatically. On 401/403 → clear token, redirect to `/login`.
- **Rep green:** `#8cc65d` | dark green: `#006600`
- **Modals:** `<Transition name="fade">` + `fixed inset-0 z-50` overlays
- **TypeScript:** use `ReturnType<typeof setTimeout>` not `NodeJS.Timeout`
- **`PortalPage.vue`** uses inline `defineComponent()` + `h()` for sub-components — intentional, don't refactor to separate files
- **Image uploads:** downscale to 1600px long-edge via canvas before upload (`downscaleImageFile()` in `Edit_Portal.vue`), JPEG 0.85
- **Socket.IO client:** use `useSocketManager` composable — don't import socket directly

### iOS (SwiftUI)
- **API auth:** `Bearer {jwtToken}` header, handle 401/403 with `AuthSession.handleUnauthorized()`
- **Image upload:** multipart form-data, downscale to 1600px, JPEG 0.85 compression
- **ViewModels:** `@MainActor`, cancel `URLSessionDataTask` in `deinit`
- **Colors:** Rep green = `Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0))`
- **Border:** `Color(UIColor(red: 0.894, green: 0.894, blue: 0.894, alpha: 1.0))`
- **`Int: Identifiable`** — use `@retroactive` to avoid conflicts

### Backend (Flask)
- **Auth:** `@jwt_required` decorator from `app/utils/auth.py`. Current user → `g.current_user`.
- **S3 uploads:** `put_object(Body=file.read())` — never `upload_fileobj()`.
- **Story blocks:** "delete all, recreate" strategy on save — `position` = array index.
- **Portal "Main Section":** auto-created on portal creation — filter out (`title != "Main Section"`) in gallery views.
- **Portal image order:** `S3Content.position` column (added migration `f6a7b8c9d0e1`). All S3Content reads must `ORDER BY position, id` — 4 read paths + `main_image_url` in `Portal.py`.
- **Portal create:** returns early (201) before S3 uploads; images upload in background via `socketio.start_background_task`. Kill-switch: `ASYNC_PORTAL_IMAGE_UPLOAD=false` env var.
- **Rate limiting:** Flask-Limiter on `/register` (10/hr), `/login` (20/min), portal creation (10/day).
- **CORS:** controlled by `WEB_APP_ORIGIN` env var (prod web URL) + `CORS_ALLOW_LOCALHOST=true` for local dev against staging.
- **Admin user:** user ID 45 = Adam. `users_types_id = 3` = Admin in DB checks.

### Payments (Stripe)
- **Checkout sessions:** `POST /api/public/create_checkout_session` → Stripe hosted page → return URL → `GET /api/public/checkout_session_status`.
- **Stripe Connect:** portals can set up Connect accounts for receiving payouts. Return URL: `/stripe-connect-return`.
- **Staging:** always use `STRIPE_SECRET_KEY=sk_test_...` on staging — never real charges.

### Real-time (Socket.IO)
- Server: `async_mode="gevent"`, worker class `GeventWebSocketWorker` (in Procfile).
- Group chat messages emit `group_message` event. Direct messages use polling fallback if WS upgrade fails (Render edge limitation — harmless).
- `REDIS_URL` env var optional — enables multi-worker message queue (not needed for single worker).

### DB Migrations
- **Must run from:** `my-ios-app/Python_Backend/your-app/` — wrong directory breaks everything.
- **New NOT NULL columns** must have `server_default='value'` in the migration file, not just Python `default=`. Without it, migration fails on existing rows.
- **Eventlet warnings on Render shell are harmless** — ignore `RuntimeError: Working outside of application context`. Focus on `INFO [alembic]` lines and the final revision ID.
- **Rollback:** `flask db downgrade -1` (then `flask db current`).
- **Staging first:** always test migrations on staging before prod. Staging shell: Render dashboard → staging service → Shell tab.
- **Current prod head:** `f6a7b8c9d0e1`

---

## Lookup Tables (require seed data on fresh DB)

These tables must be pre-populated — a fresh staging DB needs them seeded via `flask shell`:

| Table | Rows |
|-------|------|
| `user_types` | 1=Lead, 2=Manager, 3=Designer, 4=Engineer, 5=Writer, 6=Other |
| `reporting_increments` | 1=Monthly, 2=Weekly, 3=Daily |
| `skills` | 45 entries — run `PYTHONPATH=. python app/routes/scripts/add_skills.py` |

---

## Key Files
- `app/__init__.py` — Flask app factory, all blueprint registration, CORS origins, limiter init, SocketIO config
- `app/utils/auth.py` — `@jwt_required` decorator
- `app/utils/mail_utils.py` — Resend email helper
- `app/utils/welcome_dm.py` — `send_welcome_dm_once()`, `send_founder_dm_once()`
- `app/routes/Portal_Routes/Portal_Details.py` — portal create (with background S3 upload) + portal read
- `app/routes/Portal_Routes/Portal_GraphicSections.py` — image upload/reorder for portal sections
- `app/models/s3Content_Models/s3Content.py` — `S3Content` model with `position` column
- `APIConfig.swift` — iOS `baseURL` constant
- `Components.swift` — `AuthSession`, `GrowingTextEditor`, `SafariWebView`
- `web-app/src/pages/utils/api.ts` — axios instance (always use this for web API calls)

---

## Commented-Out Features (Ready to Activate)
- **Portal approval workflow** — admin approve/reject for new portals. 6 uncomments to activate (details in gitignored `PORTAL_APPROVAL_PLAN.md`).

---

## Stage 2 Roadmap (context for AI work)
1. **Intelligent Onboarding** — intent capture → interest tags → location → instant matches (Portals + People + Goal Teams). MVP: tag + location matching. Advanced: vector embeddings.
2. **AI Goal Team Workflows** — observe patterns in Goal Team chats → suggest workflow templates → automate drafts (emails, social posts, checklists). All AI actions require human approval.

---

## Gitignored Private Files
- `Python_Backend/DB_MIGRATION_WORKFLOW.md` — full migration runbook (must-read before any schema change)
- `Python_Backend/SECURITY_PERFORMANCE_BACKLOG.md` — security/performance backlog incl. bot/spam-defense playbook
- `PORTAL_APPROVAL_PLAN.md` — approval workflow plan + activation steps
- `AI_INTEGRATION_ANALYSIS.md` — AI stack analysis and decisions
- `STAGING_SETUP.md` — staging environment setup runbook
- `TODO.md` — internal working task list
