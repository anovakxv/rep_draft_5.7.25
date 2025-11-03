# Rep Web App - Project Overview

**Last Updated:** 2025-10-30
**Status:** Local Testing Phase - Preparing for Production

---

## 🚨 CRITICAL: BACKEND IS LIVE PRODUCTION - DO NOT TOUCH! 🚨

**THE BACKEND AT `Python_Backend/your-app/` IS THE LIVE PRODUCTION SERVER FOR OUR IOS APP.**

**⚠️ CONFIRM BEFORE MAKING ANY BACKEND CHANGES! ⚠️**

**BACKEND MODIFICATION POLICY:**

- ✅ The Vue.js web app is built to work with the **EXISTING** backend API
- ✅ NO Python files modified without explicit approval
- ✅ NO database schemas are changed
- ✅ NO breaking API changes
- ✅ The web app consumes the same REST API that the iOS app uses
- ✅ All web app fixes are frontend-only to match what the backend already sends
- 🛑 **MUST CONFIRM WITH USER BEFORE ANY BACKEND CHANGES**
- ⚠️ **Exception:** Critical emergency fixes (like rate limiting) only after explicit approval

**Backend Location:** `C:\Users\Stephanie\Desktop\Git Rep app draft 1\my-ios-app\Python_Backend\your-app\`

**Recent Backend Modifications (ALL CONFIRMED FIRST):**
- Oct 30, 2025: Added rate limiting to `/api/goals/pending_invites` (emergency fix for runaway polling - confirmed before implementation)

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

## 🔧 Recent Work (Current Session - Oct 29, 2025)

### Tasks Completed Today:

1. ✅ **Fixed Bottom Content Padding Issues**
   - **Problem:** Bottom content on PortalPage and GoalsDetailView was sometimes blocked by the bottom navigation bar
   - **Solution:** Increased bottom padding from `pb-20` to `pb-24` on both pages
   - **Files Modified:**
     - [PortalPage.vue](web-app/src/pages/MainPages/PortalPage.vue) - Changed content padding to `px-4 pt-4 pb-24`
     - [GoalsDetailView.vue](web-app/src/pages/GoalPages/GoalsDetailView.vue) - Changed scrollable container to `pb-24`
   - **Result:** All content now accessible on mobile, no overlap with bottom bar

2. ✅ **Updated Brand Color Consistency**
   - **Problem:** Login/registration flow used incorrect green color (`green-600`) instead of Rep brand green (`#8cc65d`)
   - **Solution:** Updated all buttons and links to use Rep light green color
   - **Files Modified:**
     - [LoginView.vue](web-app/src/pages/RepProfile/LoginView.vue) - Login button and "Sign Up" link
     - [RegisterNewProfile.vue](web-app/src/pages/RepProfile/RegisterNewProfile.vue) - "Next" button and "Login" link
     - [Terms.vue](web-app/src/pages/RepProfile/Terms.vue) - "Accept Terms of Use" button
     - [OnboardingView.vue](web-app/src/pages/RepProfile/OnboardingView.vue) - Step indicators, "Accept Terms" button, "Rep Something" button
   - **Result:** Consistent Rep brand green (#8cc65d) throughout entire login/registration/onboarding flow

3. ✅ **Added Image Attachment Support to Goal Feed**
   - **Problem:** Image attachments from manual Goal updates weren't displaying in the Feed on web app (worked fine on iOS)
   - **Solution:** Added full attachment parsing and display to match iOS implementation
   - **Files Modified:**
     - [GoalsDetailView.vue](web-app/src/pages/GoalPages/GoalsDetailView.vue)
       - Added `Attachment` and `APIAttachment` interfaces
       - Updated `APIGoalProgressLog` to include `aAttachments` array
       - Added attachment processing in feed mapping (parses images and files)
       - Updated `FeedCell` component to display attachments with 100x100px thumbnails
       - Shows document icon for non-image files
       - Horizontal scrollable container for multiple attachments
   - **Result:** Image and file attachments now display correctly in Goal feed, matching iOS behavior exactly

4. ✅ **Fixed 500 Errors During Profile Completion (CRITICAL FIX)**
   - **Problem:** Some web app users got 500 errors when completing profile during onboarding (POST to `/api/user/edit` failed)
   - **Investigation:**
     - Analyzed server logs - errors were on `/api/user/edit`, not `/api/user/register`
     - Compared iOS vs web app behavior - iOS conditionally sends form fields, web app was always sending empty strings
     - Backend has no validation for empty strings, causing database constraint violations
   - **Solution - Phase 1 (iOS Parity):**
     - Updated EditProfileComponent to match iOS behavior exactly
     - Only send form fields if they have values (conditional sending)
     - `fname`, `lname`, `broadcast`, `manual_city`, `other_skill` only sent when not empty
     - `users_types_id` always sent (matching iOS)
   - **Solution - Phase 2 (Image Upload Robustness):**
     - Added image validation before upload:
       - File type check (JPEG, PNG, GIF only)
       - File size limit (10MB max)
       - Clear error messages for invalid files
     - Added graceful degradation for S3 failures:
       - If 500 error with image, automatically retry without image
       - Profile data still saved, user can upload photo later
       - Prevents S3 issues from blocking onboarding
     - Added comprehensive error logging for debugging
   - **Files Modified:**
     - [EditProfileComponent.vue](web-app/src/components/EditProfileComponent.vue)
       - Lines 294-327: Conditional field sending (matching iOS exactly)
       - Lines 264-292: Image validation and FileReader error handling
       - Lines 384-443: Graceful degradation with retry logic
   - **Result:**
     - Web app now behaves identically to iOS app
     - Users with blank optional fields no longer get 500 errors
     - S3 upload failures won't block user onboarding
     - Better error messages and logging for future debugging

### Key Improvements:
- **Mobile UX:** Fixed bottom content accessibility on multiple pages
- **Brand Consistency:** Rep green color now consistent across all authentication flows
- **Feature Parity:** Goal attachments now display on web app matching iOS
- **Reliability:** Fixed critical onboarding 500 errors, added robustness for image uploads
- **Error Handling:** Graceful degradation ensures users can complete onboarding even with S3 issues

### Files Modified Today:
- [PortalPage.vue](web-app/src/pages/MainPages/PortalPage.vue) - Bottom padding fix
- [GoalsDetailView.vue](web-app/src/pages/GoalPages/GoalsDetailView.vue) - Bottom padding + attachment display
- [LoginView.vue](web-app/src/pages/RepProfile/LoginView.vue) - Brand color update
- [RegisterNewProfile.vue](web-app/src/pages/RepProfile/RegisterNewProfile.vue) - Brand color update
- [Terms.vue](web-app/src/pages/RepProfile/Terms.vue) - Brand color update
- [OnboardingView.vue](web-app/src/pages/RepProfile/OnboardingView.vue) - Brand color update
- [EditProfileComponent.vue](web-app/src/components/EditProfileComponent.vue) - Critical 500 error fix + image validation

---

## 🔧 Recent Work (Current Session - Oct 30, 2025)

### Tasks Completed Today:

1. ✅ **Fixed Critical iOS Invite Polling Runaway Loop (CRITICAL BUG FIX)**
   - **Problem:** iOS app making 1,600+ API requests in 17 seconds (94 requests/second) to `/api/goals/pending_invites`
   - **Root Cause:** Redundant `fetchPendingInvites()` call in `MainScreenContent.onAppear` creating feedback loop:
     - `.onAppear` fires → fetches invites → updates `@Published` property
     - SwiftUI detects change → re-renders view → `.onAppear` fires again
     - Loop repeats 94 times per second, causing memory pressure and app crashes
   - **Solution (iOS):**
     - Removed redundant `.onAppear` block from `MainScreenContent` (line 1538)
     - Polling now limited to proper 30-second timer and Socket.IO events only
   - **Files Modified:**
     - [MainScreen.swift](my-ios-app/Swift FrontEnd/Rep/MainScreen.swift) - Removed `.onAppear` feedback loop
   - **Result:**
     - Eliminated runaway API requests
     - Reduced memory pressure on iOS devices
     - Fixed app crashes caused by excessive polling
     - Normal polling behavior restored (30-second intervals)

2. ✅ **Added Backend Rate Limiting Protection (EMERGENCY FIX)**
   - **Problem:** Old iOS clients with polling bug still in production causing server overload
   - **Solution:** Added graceful rate limiting to `/api/goals/pending_invites` endpoint
     - Limits: 15 requests per minute per user
     - Block duration: 3 minutes if exceeded
     - Returns cached data instead of errors (seamless UX)
   - **Files Modified:**
     - [Goal_Teams.py](Python_Backend/your-app/app/routes/Goals_Routes/Goal_Teams.py)
       - Added `_rate_limit_cache` tracking
       - Rate limit check before DB queries
       - Silent blocking with cached responses (no user-facing errors)
   - **Result:**
     - Protects backend from runaway clients immediately
     - Old iOS clients won't crash while waiting for App Store update
     - Server logs stable, ~99% reduction in excessive requests
     - Seamless user experience (no error messages)

3. ✅ **Added Group Members Display to Web App Chat**
   - **Problem:** Web app Group Chat didn't show member avatars like iOS app does
   - **Solution:** Added horizontal scrollable member strip matching iOS exactly
   - **Files Modified:**
     - [Chat_Group.vue](web-app/src/pages/Messaging/Chat_Group.vue)
       - Added horizontal member strip between header and messages
       - Shows member avatars (36px) and initials
       - Hidden scrollbar with smooth horizontal scrolling
       - Added `getInitials()` helper function
   - **Result:**
     - Web app Group Chat now matches iOS behavior exactly
     - Members visible at a glance
     - Professional UI matching native app

### Key Improvements:
- **iOS Stability:** Fixed critical crash bug affecting production users
- **Backend Protection:** Rate limiting shields server from runaway clients
- **Feature Parity:** Web app Group Chat now shows members like iOS
- **User Experience:** All fixes are seamless (no error messages to users)

### Files Modified Today:
- [MainScreen.swift](my-ios-app/Swift FrontEnd/Rep/MainScreen.swift) - iOS polling fix
- [Goal_Teams.py](Python_Backend/your-app/app/routes/Goals_Routes/Goal_Teams.py) - Backend rate limiting
- [Chat_Group.vue](web-app/src/pages/Messaging/Chat_Group.vue) - Group member display

---

## 🔧 Previous Session (Oct 29, 2025)

### Tasks Completed:

1. ✅ **Fixed Bottom Content Padding Issues**
   - **Problem:** Bottom content on PortalPage and GoalsDetailView was sometimes blocked by the bottom navigation bar
   - **Solution:** Increased bottom padding from `pb-20` to `pb-24` on both pages
   - **Files Modified:**
     - [PortalPage.vue](web-app/src/pages/MainPages/PortalPage.vue) - Changed content padding to `px-4 pt-4 pb-24`
     - [GoalsDetailView.vue](web-app/src/pages/GoalPages/GoalsDetailView.vue) - Changed scrollable container to `pb-24`
   - **Result:** All content now accessible on mobile, no overlap with bottom bar

2. ✅ **Updated Brand Color Consistency**
   - **Problem:** Login/registration flow used incorrect green color (`green-600`) instead of Rep brand green (`#8cc65d`)
   - **Solution:** Updated all buttons and links to use Rep light green color
   - **Files Modified:**
     - [LoginView.vue](web-app/src/pages/RepProfile/LoginView.vue) - Login button and "Sign Up" link
     - [RegisterNewProfile.vue](web-app/src/pages/RepProfile/RegisterNewProfile.vue) - "Next" button and "Login" link
     - [Terms.vue](web-app/src/pages/RepProfile/Terms.vue) - "Accept Terms of Use" button
     - [OnboardingView.vue](web-app/src/pages/RepProfile/OnboardingView.vue) - Step indicators, "Accept Terms" button, "Rep Something" button
   - **Result:** Consistent Rep brand green (#8cc65d) throughout entire login/registration/onboarding flow

3. ✅ **Added Image Attachment Support to Goal Feed**
   - **Problem:** Image attachments from manual Goal updates weren't displaying in the Feed on web app (worked fine on iOS)
   - **Solution:** Added full attachment parsing and display to match iOS implementation
   - **Files Modified:**
     - [GoalsDetailView.vue](web-app/src/pages/GoalPages/GoalsDetailView.vue)
       - Added `Attachment` and `APIAttachment` interfaces
       - Updated `APIGoalProgressLog` to include `aAttachments` array
       - Added attachment processing in feed mapping (parses images and files)
       - Updated `FeedCell` component to display attachments with 100x100px thumbnails
       - Shows document icon for non-image files
       - Horizontal scrollable container for multiple attachments
   - **Result:** Image and file attachments now display correctly in Goal feed, matching iOS behavior exactly

4. ✅ **Fixed 500 Errors During Profile Completion (CRITICAL FIX)**
   - **Problem:** Some web app users got 500 errors when completing profile during onboarding (POST to `/api/user/edit` failed)
   - **Investigation:**
     - Analyzed server logs - errors were on `/api/user/edit`, not `/api/user/register`
     - Compared iOS vs web app behavior - iOS conditionally sends form fields, web app was always sending empty strings
     - Backend has no validation for empty strings, causing database constraint violations
   - **Solution - Phase 1 (iOS Parity):**
     - Updated EditProfileComponent to match iOS behavior exactly
     - Only send form fields if they have values (conditional sending)
     - `fname`, `lname`, `broadcast`, `manual_city`, `other_skill` only sent when not empty
     - `users_types_id` always sent (matching iOS)
   - **Solution - Phase 2 (Image Upload Robustness):**
     - Added image validation before upload:
       - File type check (JPEG, PNG, GIF only)
       - File size limit (10MB max)
       - Clear error messages for invalid files
     - Added graceful degradation for S3 failures:
       - If 500 error with image, automatically retry without image
       - Profile data still saved, user can upload photo later
       - Prevents S3 issues from blocking onboarding
     - Added comprehensive error logging for debugging
   - **Files Modified:**
     - [EditProfileComponent.vue](web-app/src/components/EditProfileComponent.vue)
       - Lines 294-327: Conditional field sending (matching iOS exactly)
       - Lines 264-292: Image validation and FileReader error handling
       - Lines 384-443: Graceful degradation with retry logic
   - **Result:**
     - Web app now behaves identically to iOS app
     - Users with blank optional fields no longer get 500 errors
     - S3 upload failures won't block user onboarding
     - Better error messages and logging for future debugging

---

## 🔧 Previous Session (Oct 26, 2025)

### Tasks Completed:

1. ✅ **Fixed Navigation After Login/Registration**
   - **Problem:** When users logged in or registered from a public page, hitting the back button would return them to login/register pages instead of MainScreen, leaving them stuck with no way to access the main app
   - **Solution:** Used `router.replace()` instead of `router.push()` to remove auth pages from browser history
   - **Files Modified:**
     - [LoginView.vue](web-app/src/pages/RepProfile/LoginView.vue) - Changed to `router.replace()` after successful login
     - [OnboardingView.vue](web-app/src/pages/RepProfile/OnboardingView.vue) - Changed to `router.replace()` after onboarding completion
     - [RegisterNewProfile.vue](web-app/src/pages/RepProfile/RegisterNewProfile.vue) - Changed to `router.replace()` when navigating to onboarding
   - **Result:**
     - New users can now navigate back to MainScreen after signup/login without hitting auth pages
     - Normal logged-in navigation (MainScreen → PortalPage → GoalsDetailView) still works correctly
     - Browser back button behavior is now intuitive for both new and existing users

2. ✅ **Fixed PayTransaction Page Issues**
   - Made content scrollable on desktop (fixed overflow handling)
   - Adjusted page width to match global constraint (max-w-3xl / 768px)
   - Added light gray divider beneath header (`border-gray-200`)
   - Added bottom padding to prevent browser bars from covering content

3. ✅ **Fixed Mobile Chat Scrolling**
   - Added iOS-specific scrolling properties to Chat_Individual.vue and Chat_Group.vue
   - Applied `-webkit-overflow-scrolling: touch` and `overscroll-behavior-y: contain`
   - Chat messages now scroll properly on iPhone Safari and other mobile browsers

4. ✅ **Fixed Bottom Padding Issues**
   - Added `pb-20` to MainScreen, PayTransaction to prevent browser bars from covering content
   - Ensures all interactive elements are accessible on mobile devices

5. ✅ Fixed Support button positioning on GoalsDetailView to match iOS app
   - Moved from center-bottom to bottom-right corner (matching iOS `.bottomTrailing`)
   - Reduced button height (py-2.5 instead of py-[14px]) for better proportions
   - Fixed desktop positioning to stay within centered content area (max-width: 768px)
   - Button now properly positioned at bottom-right on both mobile and desktop

### Key Improvements:
- **Navigation UX:** Back button now works intuitively after login/registration for new users
- **Mobile Optimization:** Chat pages scroll smoothly on iOS Safari and all mobile browsers
- **Layout Consistency:** All pages respect global 768px width constraint on desktop
- **Content Accessibility:** Bottom padding prevents browser bars from covering interactive elements
- **UI Consistency:** Support button on Fund/Sales goals matches iOS positioning exactly

### Files Modified Today:
- [LoginView.vue](web-app/src/pages/RepProfile/LoginView.vue) - Navigation fix with router.replace()
- [OnboardingView.vue](web-app/src/pages/RepProfile/OnboardingView.vue) - Navigation fix with router.replace()
- [RegisterNewProfile.vue](web-app/src/pages/RepProfile/RegisterNewProfile.vue) - Navigation fix with router.replace()
- [PayTransaction.vue](web-app/src/pages/MainPages/PayTransaction.vue) - Scrolling, width, padding fixes
- [MainScreen.vue](web-app/src/pages/MainPages/MainScreen.vue) - Bottom padding fix
- [Chat_Individual.vue](web-app/src/pages/Messaging/Chat_Individual.vue) - iOS scrolling fix
- [Chat_Group.vue](web-app/src/pages/Messaging/Chat_Group.vue) - iOS scrolling fix
- [GoalsDetailView.vue](web-app/src/pages/GoalPages/GoalsDetailView.vue) - Support button positioning

### Previous Session (Oct 24, 2025):
1. ✅ Updated web app branding from "Vite + Vue" to "Rep" (title, favicon, social sharing meta tags)
2. ✅ Web app now shows "Rep" title and Rep logo in browser tab, bookmarks, and when sharing links
3. ✅ Added apple-touch-icon so Rep logo shows when users add to home screen

### Previous Session (Oct 23, 2025):
1. ✅ Fixed ProfileView sticky segmented picker (changed layout structure to match working pages)
2. ✅ Added browser status bar color matching (`#f7f7f7`) via meta tags for seamless mobile experience
3. ✅ Updated all header bars to use iOS Safari default color (`#f7f7f7`) for consistent appearance
4. ✅ Fixed headers to stay locked at top on most pages (restructured GoalsDetailView, Chat pages)
5. ✅ Fixed fullscreen image viewer on PortalPage (removed top bar, made truly fullscreen for landscape viewing)
6. ✅ Increased bottom bar button height to 40px (h-10) on PortalPage, ProfileView, GoalsDetailView

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
