# Rep Web App - Project Overview

**Last Updated:** 2025-11-07
**Status:** Production - Vue.js web app + iOS app + Flask backend

---

## 🚨 CRITICAL: BACKEND IS LIVE PRODUCTION - DO NOT TOUCH! 🚨

**THE BACKEND AT `Python_Backend/your-app/` IS THE LIVE PRODUCTION SERVER FOR OUR IOS APP.**

**⚠️ CONFIRM BEFORE MAKING ANY BACKEND CHANGES! ⚠️**

**BACKEND MODIFICATION POLICY:**
- ✅ NO Python files modified without explicit approval
- ✅ NO database schemas changed
- ✅ NO breaking API changes
- 🛑 **MUST CONFIRM WITH USER BEFORE ANY BACKEND CHANGES**

**Backend Location:** `C:\Users\Stephanie\Desktop\Git Rep app draft 1\my-ios-app\Python_Backend\your-app\`

---

## 📁 Project Structure

```
C:\Users\Stephanie\Desktop\Git Rep app draft 1\my-ios-app\
├── my-ios-app/                      # Swift iOS App (READ ONLY)
├── web-app/                         # Vue.js Web App (Frontend)
└── Python_Backend/your-app/         # 🚨 LIVE PRODUCTION BACKEND 🚨
    ├── app/
    │   ├── tasks/                   # NEW: Background jobs (email summaries)
    │   ├── routes/                  # API endpoints
    │   ├── models/                  # Database models
    │   ├── scheduler.py             # NEW: Job scheduler (WORKER_MODE gate)
    │   └── __init__.py
    ├── worker.py                    # NEW: Background worker entry point
    └── requirements.txt
```

---

## 🎯 Project Overview

**Goal:** Vue.js web app mirroring iOS Swift app functionality using existing production Flask backend API.

**Tech Stack:**
- **Frontend:** Vue 3 (Composition API), TypeScript, Tailwind CSS, Vite
- **Backend:** Python Flask (existing, minimal modifications)
- **Auth:** JWT tokens
- **Real-time:** Socket.IO for messaging
- **Email:** SendGrid (daily summaries, password reset)
- **Deployment:** Render (backend), Vercel (frontend)

**Core Features:**
- Authentication, Profile Management, Portals, Goals, Messaging, Network, Payments

---

## 🔧 Current Session (Nov 7, 2025)

### ✅ Implemented Daily Email Summary Feature (MAJOR NEW FEATURE)

**Goal:** Send users a daily email digest of messages received in last 24 hours (DMs + Team Chats)

**Architecture:** Hybrid worker approach - separate background worker process for production safety

#### A. Password Reset Email Infrastructure (Prerequisite)
- Fixed SendGrid integration, domain authentication for `repsomething.com`
- Updated reset links to `www.repsomething.com/new-password`
- Beautiful HTML email template with Rep branding (#8cc65d green)
- 1-hour token expiration for security
- Verified sender: `contact@repsomething.com`

**Files Modified:**
- [LoginActions.py](Python_Backend/your-app/app/routes/User_Routes/LoginActions.py) - Password reset endpoint
- [mail_utils.py](Python_Backend/your-app/app/utils/mail_utils.py) - Default from_email
- [ResetPassword.vue](web-app/src/pages/RepProfile/ResetPassword.vue) - Brand colors
- [NewPassword.vue](web-app/src/pages/RepProfile/NewPassword.vue) - Brand colors

#### B. Daily Email Summary Implementation

**Architecture: Hybrid Worker Approach**
- **Why:** Production safety - isolates background jobs from web API
- **How:** Two services on Render using same codebase:
  1. **Web Service:** Serves API, `WORKER_MODE=false` (scheduler inactive)
  2. **Background Worker:** Runs scheduler only, `WORKER_MODE=true`

**New Files Created (7 total):**

1. **`app/tasks/__init__.py`** - Tasks module init
2. **`app/tasks/daily_email_summary.py`** (280 lines)
   - Core functions: `get_users_with_email_preference()`, `get_direct_messages_for_user()`, `get_group_messages_for_user()`, `send_daily_summary()`
   - Helper functions: `truncate_text()`, `time_ago()`, `build_email_html()`
   - Read-only queries (last 24 hours), excludes user's own group messages
3. **`app/tasks/email_templates/daily_summary.html`**
   - HTML email with Rep branding (#8cc65d green)
   - Sections: Direct Messages (10 recent), Team Chats (15 recent), CTA button, Unsubscribe link
4. **`app/routes/User_Routes/TriggerDailySummary.py`**
   - Admin-only manual trigger: `POST /api/user/trigger_daily_summary`
   - Returns stats: `{sent, skipped, errors, total_users}`
5. **`app/scheduler.py`**
   - Flask-APScheduler configuration
   - **Safety:** Only starts if `WORKER_MODE=true` env var set
   - Job: Daily at 8:00 AM UTC, calls `send_daily_summary()`
6. **`worker.py`**
   - Entry point for background worker process
   - Requires `WORKER_MODE=true`, graceful shutdown handling

**Modified Files (2 total - CAREFULLY DONE):**

1. **`requirements.txt`** - Added `flask-apscheduler` (line 18)
2. **`app/__init__.py`** (4 surgical edits)
   - Line 20: `from app.scheduler import init_scheduler`
   - Line 104: Import TriggerDailySummary blueprint
   - Line 121: Register blueprint at `/api/user`
   - Line 189: `init_scheduler(app)` before `return app`

**Deployment Configuration:**

**Render Setup (Two Services):**
1. **Web Service (Existing):**
   - Start: `gunicorn --worker-class eventlet -w 1 wsgi:app`
   - Env: `WORKER_MODE=false` (or unset) + all existing env vars

2. **Background Worker (New):**
   - Start: `python worker.py`
   - Env: `WORKER_MODE=true` ⭐ + copy ALL env vars from web service (DATABASE_URL, SENDGRID_API_KEY, JWT_SECRET, PASS_SALT, etc.)

**Testing Strategy:**
- **Phase 1 (Current):** Manual testing via `POST /api/user/trigger_daily_summary` as admin
- **Phase 2 (Future):** Enable automatic scheduler on background worker

**Business Logic:**
- **Who:** All users with email addresses (future: check `notification_settings`)
- **When:** Daily at 8:00 AM UTC
- **What:** Messages from last 24 hours
- **Exclusions:** Users with no messages, user's own messages in groups

**Safety Mechanisms:**
1. Env var gate (`WORKER_MODE=true` required)
2. Admin-only manual trigger
3. Graceful error handling (logs, continues on failures)
4. Read-only queries (no database writes)
5. SendGrid rate limit awareness

**Future Enhancements:**
- User preferences (enable/disable, timing, frequency)
- Unsubscribe functionality
- Weekly digest option
- Smart timing per user timezone
- Email analytics via SendGrid webhooks

**Current Status:**
- ✅ Code complete and deployed
- ✅ Scheduler inactive (safe for production)
- ✅ Manual trigger ready for testing
- ⏳ Phase 1 testing pending
- ⏳ Phase 2 (automatic scheduling) after successful testing

---

## 🔧 Recent Work (Oct 30, 2025)

1. ✅ **Fixed Critical iOS Invite Polling Runaway Loop**
   - Problem: 1,600+ API requests in 17 seconds (94 req/sec) to `/api/goals/pending_invites`
   - Solution: Removed redundant `.onAppear` block causing feedback loop
   - File: [MainScreen.swift](my-ios-app/Swift FrontEnd/Rep/MainScreen.swift)

2. ✅ **Added Backend Rate Limiting**
   - Added graceful rate limiting to `/api/goals/pending_invites` (15 req/min per user)
   - File: [Goal_Teams.py](Python_Backend/your-app/app/routes/Goals_Routes/Goal_Teams.py)

3. ✅ **Group Members Display in Web App**
   - Added horizontal member strip to Group Chat matching iOS
   - File: [Chat_Group.vue](web-app/src/pages/Messaging/Chat_Group.vue)

---

## 🔧 Recent Work (Oct 29, 2025)

1. ✅ **Fixed Bottom Content Padding** - Increased from `pb-20` to `pb-24` on PortalPage and GoalsDetailView
2. ✅ **Brand Color Consistency** - Updated to Rep green (#8cc65d) across login/registration/onboarding flow
3. ✅ **Goal Feed Image Attachments** - Added attachment display matching iOS (100x100px thumbnails)
4. ✅ **Fixed 500 Errors During Profile Completion** - Conditional field sending + image validation + graceful degradation for S3 failures

---

## 🔧 Previous Sessions (Oct 23-26, 2025)

**Oct 26:**
- Fixed navigation after login/registration (router.replace() to prevent back button issues)
- Fixed mobile chat scrolling (iOS-specific properties)
- Support button positioning on GoalsDetailView

**Oct 24:**
- Updated web app branding from "Vite + Vue" to "Rep" (title, favicon, meta tags)

**Oct 23:**
- Fixed ProfileView sticky segmented picker
- Browser status bar color matching (#f7f7f7)
- Headers stay locked at top

---

## 📝 Development Notes

### API Endpoints (Existing - No Changes)
- Auth: `/api/user/login`, `/api/user/register`, `/api/user/forgot_password`
- Portals: `/api/purpose/*`
- Goals: `/api/goal/*`
- Messaging: `/api/message/*`
- Users: `/api/user/*`
- **NEW:** `/api/user/trigger_daily_summary` (admin only, manual email trigger)

### Key Technical Patterns
- **API Calls:** Centralized `api.ts` with JWT injection
- **Routing:** Vue Router with auth guards
- **Styling:** Tailwind CSS (`bg-gray-50`, `max-w-2xl`, etc.)
- **Real-time:** Socket.IO via `RealtimeSocketManager`
- **Email:** SendGrid via `mail_utils.py`
- **Background Jobs:** Flask-APScheduler (WORKER_MODE gate)

### Backend Compatibility
- ✅ 100% compatible with existing backend API
- ✅ All API responses match iOS app
- ✅ Frontend adapts to backend's data structure

---

## 🚀 Next Steps

1. **Phase 1 Testing:** Test manual email summary trigger as admin
2. **Phase 2 Deployment:** Create background worker service on Render with `WORKER_MODE=true`
3. Continue web app feature development
4. Deploy frontend to Vercel (domain: repsomething.com)

---

## 📞 Important Reminders

**🚨 NEVER MODIFY BACKEND FILES WITHOUT EXPLICIT APPROVAL! 🚨**

The backend at `Python_Backend/your-app/` serves the live iOS app in production.

**Development directories:**
- Web app: `web-app/` (frontend only)
- Swift files: READ ONLY for reference
- Backend: CONFIRM BEFORE ANY CHANGES

**Dev server:**
```bash
cd "C:\Users\Stephanie\Desktop\Git Rep app draft 1\my-ios-app\web-app"
npm run dev  # http://localhost:5173/
```

---

*This document is updated as we progress through development.*
