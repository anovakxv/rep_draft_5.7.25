# Rep Web App - Project Overview

**Last Updated:** 2025-10-23
**Status:** Local Testing Phase - Preparing for Production

---

## 🚨 CRITICAL: BACKEND IS LIVE PRODUCTION - DO NOT MODIFY! 🚨

**THE BACKEND AT `Python_Backend/your-app/` IS THE LIVE PRODUCTION SERVER FOR OUR IOS APP.**

**WE DO NOT AND WILL NOT TOUCH ANY BACKEND FILES!**

- ✅ The Vue.js web app is built to work with the **EXISTING** backend API
- ✅ NO Python files are modified
- ✅ NO database schemas are changed
- ✅ NO API routes are altered
- ✅ The web app consumes the same REST API that the iOS app uses
- ✅ All fixes are frontend-only to match what the backend already sends

**Backend Location:** `C:\Users\Stephanie\Desktop\Git Rep app draft 1\my-ios-app\Python_Backend\your-app\`

---

## 📁 Project Structure

```
C:\Users\Stephanie\Desktop\Git Rep app draft 1\my-ios-app\
│
├── my-ios-app/                      # Swift iOS App (Reference Only - READ ONLY)
│   └── Swift FrontEnd/Rep/          # 38 Swift files used as reference
│
├── web-app/                         # Vue.js Web App (OUR WORK - FRONTEND ONLY)
│   ├── src/
│   │   ├── pages/                   # All page components
│   │   │   ├── MainPages/           # MainScreen, PortalPage, Edit_Portal
│   │   │   ├── GoalPages/           # GoalsDetailView, EditGoal
│   │   │   ├── Messaging/           # Chat_Individual, Chat_Group, NewGroupChat
│   │   │   └── RepProfile/          # ProfileView, Settings, LoginView, etc.
│   │   ├── components/              # Reusable UI components
│   │   ├── pages/utils/             # API utilities (api.ts)
│   │   ├── assets/                  # CSS, images
│   │   └── router.ts                # Route configuration
│   ├── package.json
│   ├── vite.config.ts
│   └── tsconfig.app.json
│
└── Python_Backend/                  # 🚨 DO NOT TOUCH - LIVE PRODUCTION! 🚨
    └── your-app/
        ├── app/
        │   ├── routes/              # 43+ route files
        │   ├── models/              # Database models
        │   └── __init__.py
        └── run.py
```

---

## 🎯 Project Overview

**Goal:** Build a Vue.js web app that mirrors the iOS Swift app functionality, using the existing production backend API.

**Approach:**
- Reference the Swift iOS app codebase to understand UI/UX patterns
- Build Vue.js components that match iOS behavior
- Connect to existing backend REST API endpoints
- NO backend modifications whatsoever

**Tech Stack:**
- **Frontend:** Vue 3 (Composition API), TypeScript, Tailwind CSS, Vite
- **Backend:** Python Flask (existing, untouched)
- **Auth:** JWT tokens via existing `/api/user/login` endpoint
- **Real-time:** Socket.IO for messaging (existing backend implementation)

---

## ✅ Completed Features

### Core Functionality (100% Complete)
- **Authentication:** Login, Registration, Onboarding, Password Reset
- **Profile Management:** View/Edit Profile, Settings, Payments
- **Purpose (Portal) Management:** View, Create, Edit, Delete Portals
- **Goal Management:** View, Create, Edit, Invite Team Members
- **Messaging:** Direct Messages, Group Chats, Real-time updates via Socket.IO
- **Network:** View member network, search users
- **Public Features:** Public portal/goal browsing, guest payments via Stripe

### UI/UX Matching iOS App
- Consistent light gray top bars across all pages (`bg-gray-50`)
- Navigation patterns matching iOS (back buttons, route navigation)
- Action menus for creating portals/goals
- Modal sheets for editing and team invitations
- Message bubbles with profile pictures
- Typing indicators in chats
- Loading states and error handling

### Technical Improvements
- Centralized API client (`api.ts`) with JWT injection
- TypeScript type safety
- Real-time Socket.IO integration
- Vite build optimization
- Responsive design with Tailwind CSS

---

## 🔧 Recent Work (Current Session)

### Tasks Completed Today:
1. ✅ Made all top bars use very light gray (`bg-gray-50`) across all pages
2. ✅ Added back button to Settings page
3. ✅ Fixed ProfileView ActionMenu buttons to navigate to Add Purpose/Goal pages
4. ✅ Removed attachment functionality from chat pages (backend doesn't support yet)
5. ✅ Fixed EditGoal page header width to match content area
6. ✅ Created NewGroupChat page for team chat creation
7. ✅ Added route for `/chat/group/new`

### Files Modified Today:
- [MainScreen.vue](web-app/src/pages/MainPages/MainScreen.vue)
- [PortalPage.vue](web-app/src/pages/MainPages/PortalPage.vue)
- [Chat_Individual.vue](web-app/src/pages/Messaging/Chat_Individual.vue)
- [Chat_Group.vue](web-app/src/pages/Messaging/Chat_Group.vue)
- [GoalsDetailView.vue](web-app/src/pages/GoalPages/GoalsDetailView.vue)
- [ProfileView.vue](web-app/src/pages/RepProfile/ProfileView.vue)
- [Settings.vue](web-app/src/pages/RepProfile/Settings.vue)
- [EditGoal.vue](web-app/src/pages/GoalPages/EditGoal.vue)
- [NewGroupChat.vue](web-app/src/pages/Messaging/NewGroupChat.vue) - **NEW FILE**
- [router.ts](web-app/src/router.ts)

---

## 🧪 Testing Status

**Local Testing:** In Progress
- Dev server: `http://localhost:5173/`
- Testing authentication, navigation, and core features
- Verifying API compatibility with production backend

**Production Deployment:** Not Yet
- Backend: Will deploy to Render
- Frontend: Will deploy to Vercel (domain: repsomething.com)
- Full testing required before production launch

---

## 📝 Development Notes

### API Endpoints (All Existing - No Changes)
- Authentication: `/api/user/login`, `/api/user/register`
- Portals: `/api/purpose/*`
- Goals: `/api/goal/*`
- Messaging: `/api/message/*`
- Users: `/api/user/*`
- Payments: `/api/payment/create_checkout_session`, `/api/payment/create_payment_intent`
- Stripe: `/api/stripe/create_account_link`, `/api/stripe/account_status`

### Key Technical Patterns
- **API Calls:** Use centralized `api.ts` with automatic JWT injection
- **Routing:** Vue Router with authentication guards
- **Styling:** Tailwind utility classes (`bg-gray-50`, `max-w-2xl`, etc.)
- **Real-time:** Socket.IO connection via `RealtimeSocketManager` (window global)
- **Forms:** Vue 3 `ref()` for reactive state

### Backend Compatibility
- ✅ 100% compatible with existing backend API
- ✅ All API responses match what iOS app receives
- ✅ No backend modifications needed
- ✅ Frontend adapts to backend's data structure

---

## 🚀 Next Steps

1. Continue local testing of all features
2. Fix any bugs discovered during testing
3. Prepare backend deployment to Render
4. Deploy frontend to Vercel
5. Production testing with live backend
6. Launch web app to users

---

## 📞 Important Reminders

**🚨 NEVER MODIFY BACKEND FILES! 🚨**

The backend at `Python_Backend/your-app/` is serving the live iOS app in production. Any changes could break the production app for real users.

**All development work is in:**
- `web-app/` directory (frontend only)
- References to Swift files are READ ONLY for understanding behavior

**Current working directory for development:**
```
cd "C:\Users\Stephanie\Desktop\Git Rep app draft 1\my-ios-app\web-app"
npm run dev
```

---

*This document is updated as we progress through local testing and development.*
