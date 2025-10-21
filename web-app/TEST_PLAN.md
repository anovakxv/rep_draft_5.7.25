# Rep Web App - Test Plan

**Version:** 1.0
**Date:** 2025-10-20
**Status:** Ready for Testing

---

## 📋 Table of Contents
1. [Test Environment Setup](#test-environment-setup)
2. [Test Priorities](#test-priorities)
3. [Test Cases by Feature](#test-cases-by-feature)
4. [Bug Reporting](#bug-reporting)
5. [Known Limitations](#known-limitations)

---

## 🔧 Test Environment Setup

### Prerequisites
- [ ] Backend Python server running and accessible
- [ ] Node.js v16+ installed
- [ ] npm or yarn package manager

### Environment Configuration

1. **Create `.env` file** in `web-app/` directory:
```env
VITE_API_BASE_URL=http://localhost:5000
```
*Replace with your actual backend URL*

2. **Install dependencies:**
```bash
cd web-app
npm install
```

3. **Start development server:**
```bash
npm run dev
```

4. **Access the app:**
- Local: `http://localhost:5173` (or port shown in terminal)

### Test Data Requirements
- [ ] At least 2 test user accounts (for messaging/network features)
- [ ] At least 1 test portal with content
- [ ] At least 1 test goal
- [ ] Stripe test API keys configured on backend (for payment testing)

---

## 🎯 Test Priorities

### **P0 - Critical (Must Work)**
Authentication, core navigation, data loading

### **P1 - High (Should Work)**
Major features: profiles, portals, goals, messaging

### **P2 - Medium (Nice to Have)**
Polish features: animations, error states, edge cases

---

## 🧪 Test Cases by Feature

### **1. Authentication Flow** [P0]

#### 1.1 New User Registration
**Steps:**
1. Navigate to `/register`
2. Enter valid email, password (8+ chars), first name, last name
3. Click "Register"
4. Should redirect to `/onboarding`
5. Complete onboarding steps (rep type selection, bio, skills)
6. Click "Complete Onboarding"
7. Should redirect to `/main`

**Expected Result:**
- ✅ User account created in database
- ✅ JWT token stored in localStorage
- ✅ Redirected to main app
- ✅ User can access protected routes

**Edge Cases to Test:**
- [ ] Email already exists (should show error)
- [ ] Password too short (should show error)
- [ ] Empty fields (should show validation errors)

---

#### 1.2 Existing User Login
**Steps:**
1. Navigate to `/login`
2. Enter valid email and password
3. Click "Login"
4. Should redirect to `/main`

**Expected Result:**
- ✅ JWT token stored in localStorage
- ✅ User ID stored in localStorage
- ✅ Redirected to main app

**Edge Cases:**
- [ ] Wrong password (should show error)
- [ ] Non-existent email (should show error)
- [ ] Empty fields (should show validation)

---

#### 1.3 Password Reset Flow
**Steps:**
1. On login page, click "Forgot Password?"
2. Navigate to `/reset-password`
3. Enter email address
4. Click "Send Reset Link"
5. Check email for reset link (or check backend logs for token)
6. Navigate to `/new-password?token=YOUR_TOKEN`
7. Enter new password and confirm
8. Click "Reset Password"
9. Should redirect to `/login`

**Expected Result:**
- ✅ Reset email sent
- ✅ Password changed successfully
- ✅ Can login with new password

---

#### 1.4 Logout
**Steps:**
1. While logged in, navigate to `/settings`
2. Click "Logout"
3. Should clear session and redirect to `/login`

**Expected Result:**
- ✅ localStorage cleared
- ✅ Redirected to login
- ✅ Cannot access protected routes

---

### **2. Main Screen & Navigation** [P0]

#### 2.1 Main Screen Load
**Steps:**
1. Login successfully
2. Observe main screen at `/main`

**Expected Result:**
- ✅ Header shows profile picture
- ✅ Segmented picker shows OPEN/NTWK/ALL
- ✅ Plus button visible
- ✅ Content loads (portals OR people depending on last state)
- ✅ Floating toggle button visible (bottom right)

---

#### 2.2 Section Toggle (OPEN/NTWK/ALL)
**Steps:**
1. On main screen, click "OPEN"
2. Click "NTWK"
3. Click "ALL"

**Expected Result:**
- ✅ Each section loads different filtered content
- ✅ Loading skeleton shown during fetch
- ✅ Content updates without page reload

---

#### 2.3 Page Toggle (Portals ↔ People)
**Steps:**
1. Click floating toggle button (bottom right)
2. Should switch between Portals and People pages

**Expected Result:**
- ✅ Page switches smoothly
- ✅ Fade transition applied
- ✅ Content loads for new page type

---

#### 2.4 Search Functionality
**Steps:**
1. Click "+" button → "Search"
2. Search overlay appears from bottom
3. Type search query
4. Results update after debounce (~400ms)
5. Click "Cancel" to close

**Expected Result:**
- ✅ Search overlay slides up smoothly
- ✅ Results filter as you type
- ✅ Works for both portals and people
- ✅ Closes cleanly on cancel

---

### **3. User Profile** [P1]

#### 3.1 View Own Profile
**Steps:**
1. Click profile picture in header
2. Should navigate to `/profile/:userId`

**Expected Result:**
- ✅ Profile loads with user data
- ✅ Shows tabs: About, Goals, Portals, Write, Contact
- ✅ "Edit Profile" button visible
- ✅ Settings button visible

---

#### 3.2 Edit Profile
**Steps:**
1. On profile page, click "Edit Profile"
2. Navigate to `/profile/edit`
3. Update first name, last name, bio
4. Select skills from dropdown
5. Upload profile picture (optional)
6. Select rep type
7. Click "Save Changes"

**Expected Result:**
- ✅ Form populates with current data
- ✅ Skills multi-select works
- ✅ Image upload preview shows
- ✅ Changes saved to backend
- ✅ Redirected to profile page
- ✅ Updated data displayed

---

#### 3.3 Settings Page
**Steps:**
1. On profile, click settings icon
2. Navigate to `/settings`
3. Test notification toggles
4. Test password change
5. Test logout

**Expected Result:**
- ✅ All toggles save to localStorage and backend
- ✅ Password change works (with current password validation)
- ✅ Logout clears session

---

#### 3.4 View Other User's Profile
**Steps:**
1. From people list, click on another user
2. Navigate to `/profile/:otherUserId`

**Expected Result:**
- ✅ Profile loads with their data
- ✅ NO "Edit Profile" button (not your profile)
- ✅ "Message" button visible
- ✅ Can view their goals, portals, content

---

### **4. Portals** [P1]

#### 4.1 View Portal Feed
**Steps:**
1. On main screen, ensure you're on Portals page
2. Scroll through portal list

**Expected Result:**
- ✅ Portals display with image, name, subtitle
- ✅ Click portal navigates to `/portal/:id`
- ✅ Infinite scroll or pagination works

---

#### 4.2 View Portal Detail
**Steps:**
1. Click on a portal
2. Navigate to `/portal/:id`

**Expected Result:**
- ✅ Portal detail page loads
- ✅ Shows portal image, name, description
- ✅ Shows goals associated with portal
- ✅ Shows team members
- ✅ Action buttons visible (if applicable)

---

#### 4.3 Create New Portal
**Steps:**
1. Click "+" button → "Add Purpose"
2. Navigate to `/portal/edit/new`
3. Fill in portal name, description
4. Upload main image
5. Set portal as public/private
6. Click "Save" or "Create"

**Expected Result:**
- ✅ Form validation works
- ✅ Image upload works
- ✅ Portal created in database
- ✅ Redirected to portal detail page
- ✅ New portal appears in feed

---

#### 4.4 Edit Existing Portal
**Steps:**
1. On portal detail page, click "Edit" (if creator)
2. Navigate to `/portal/edit/:id`
3. Update portal details
4. Click "Save"

**Expected Result:**
- ✅ Form pre-populated with current data
- ✅ Changes saved successfully
- ✅ Redirected back to portal detail
- ✅ Updates reflected immediately

---

#### 4.5 Portal Payment Setup (Stripe Connect)
**Steps:**
1. On portal edit page, click "Setup Payments"
2. Navigate to `/portal/:id/payment-setup`
3. Click "Connect with Stripe"
4. Complete Stripe Connect flow (test mode)

**Expected Result:**
- ✅ Redirects to Stripe Connect onboarding
- ✅ Returns to app after completion
- ✅ Stripe account linked to portal
- ✅ Can receive payments

---

### **5. Goals** [P1]

#### 5.1 View Goal Detail
**Steps:**
1. From portal page or profile, click on a goal
2. Navigate to `/goal/:id`

**Expected Result:**
- ✅ Goal detail page loads
- ✅ Shows goal title, description
- ✅ Shows team members
- ✅ Shows updates/chat tabs
- ✅ Action buttons visible

---

#### 5.2 Create New Goal
**Steps:**
1. On portal page, click "Add Goal"
2. Fill in goal title, description
3. Select team members (optional)
4. Click "Create"

**Expected Result:**
- ✅ Goal created
- ✅ Appears in portal goals list
- ✅ Creator becomes team member

---

#### 5.3 Team Invitations
**Steps:**
1. On goal detail page, click "Invite Team"
2. Select users from network
3. Click "Send Invites"

**Recipient Steps:**
1. Check `/invites` page
2. See pending invitation
3. Click "Accept" or "Decline"

**Expected Result:**
- ✅ Invites sent to selected users
- ✅ Recipients see invites on `/invites` page
- ✅ Accept adds them to goal team
- ✅ Decline removes invite

---

#### 5.4 Goal Updates/Progress
**Steps:**
1. On goal detail page, click "Updates" tab
2. Post an update (if team member)
3. View update history

**Expected Result:**
- ✅ Updates display in chronological order
- ✅ Can post text updates
- ✅ Real-time updates via socket

---

### **6. Messaging** [P1]

#### 6.1 Direct Messaging
**Steps:**
1. Navigate to People page → OPEN section
2. Click on active chat OR
3. From profile, click "Message" button
4. Navigate to `/chat/dm/:userId`

**Expected Result:**
- ✅ Chat loads with message history
- ✅ Can send text messages
- ✅ Messages appear in chat bubble format
- ✅ Timestamps displayed
- ✅ Real-time message delivery via socket

---

#### 6.2 Message Attachments
**Steps:**
1. In chat, click attachment button (paperclip icon)
2. Select image or file (PDF, DOC, etc.)
3. Attachment preview appears
4. Click "Send"

**Expected Result:**
- ✅ File upload works (multipart/form-data)
- ✅ Preview shows before sending
- ✅ Can remove attachment before sending
- ✅ Recipient sees image inline or file download link
- ✅ Images clickable to view fullsize

**Edge Cases:**
- [ ] Multiple attachments (up to 5)
- [ ] Large files (should have reasonable limit)
- [ ] Invalid file types (should reject)

---

#### 6.3 Typing Indicators
**Steps:**
1. Open chat with another user
2. Start typing in message input
3. Have other user observe on their end

**Expected Result:**
- ✅ Typing indicator shows "UserName is typing..."
- ✅ Disappears after 3 seconds of inactivity
- ✅ Socket event sent/received properly

---

#### 6.4 Read Receipts
**Steps:**
1. Send a message to another user
2. Have recipient open the chat
3. Observe message status

**Expected Result:**
- ✅ Unread messages show as bold/highlighted
- ✅ After reading, shows "Read" indicator
- ✅ Only shows for messages you sent

---

#### 6.5 Group Chat
**Steps:**
1. Navigate to group chat from active chats OR
2. Click "+" → "Team Chat" to create new group
3. Navigate to `/chat/group/:chatId`

**Expected Result:**
- ✅ Group chat loads with all members
- ✅ Messages show sender name
- ✅ Can send text messages
- ✅ Can send attachments
- ✅ Group typing indicators work ("User1 and User2 typing...")
- ✅ Can view group info (members list)
- ✅ Can leave group

---

### **7. Content Creation (Write)** [P1]

#### 7.1 Create New Content
**Steps:**
1. Navigate to Profile → Write tab
2. Click "Create New Content"
3. Navigate to `/write/new`
4. Use rich text editor toolbar (bold, italic, lists, links)
5. Add images (optional)
6. Link to portal/goal (optional)
7. Toggle draft/published
8. Click "Publish" or "Save Draft"

**Expected Result:**
- ✅ Rich text editor works (formatting, lists, links)
- ✅ Image upload and preview works
- ✅ Portal/goal selection works
- ✅ Draft saved if draft mode enabled
- ✅ Published content appears in Write tab
- ✅ Redirected to profile after save

---

#### 7.2 Edit Existing Content
**Steps:**
1. On profile Write tab, click "Edit" on content block
2. Navigate to `/write/edit/:id`
3. Make changes
4. Click "Save"

**Expected Result:**
- ✅ Form pre-populated with existing content
- ✅ Can edit HTML content
- ✅ Changes saved
- ✅ Updated content displayed

---

#### 7.3 Delete Content
**Steps:**
1. On profile Write tab, click "Delete" on content block
2. Confirm deletion

**Expected Result:**
- ✅ Confirmation prompt shown
- ✅ Content deleted from database
- ✅ Removed from Write tab immediately

---

### **8. Payments & Transactions** [P1]

#### 8.1 Stripe Checkout (Donations/Payments)
**Steps:**
1. On portal or goal page, click "Support" or "Donate"
2. PayTransaction modal appears
3. Enter amount
4. Select transaction type
5. Click "Proceed to Payment"
6. Redirected to Stripe Checkout (test mode)
7. Use test card: `4242 4242 4242 4242`, any future date, any CVC
8. Complete payment
9. Redirected back to app at `/stripe-payment-return`

**Expected Result:**
- ✅ Stripe Checkout session created
- ✅ Redirects to Stripe
- ✅ Payment processes successfully
- ✅ Returns to app with success message
- ✅ Transaction recorded in database
- ✅ BroadcastChannel updates payment status

---

#### 8.2 Stripe Connect (Payout Setup)
**Steps:**
1. As portal creator, navigate to payment setup
2. Click "Connect with Stripe"
3. Complete Stripe Connect onboarding (test mode)
4. Return to app at `/stripe-connect-return`

**Expected Result:**
- ✅ Stripe Connect account created
- ✅ Account linked to portal
- ✅ Can receive payouts
- ✅ Success message displayed

---

#### 8.3 Payment History
**Steps:**
1. Navigate to `/payments`
2. View transaction history

**Expected Result:**
- ✅ All transactions listed
- ✅ Shows date, amount, type, status
- ✅ Subscription info displayed (if any)

---

### **9. UI/UX Polish** [P2]

#### 9.1 Loading States
**Steps:**
1. Navigate to any page that fetches data
2. Observe loading behavior

**Expected Result:**
- ✅ Loading skeleton shown (not just spinner)
- ✅ Smooth transition to content
- ✅ No layout shift on load

---

#### 9.2 Empty States
**Steps:**
1. Navigate to pages with no data (e.g., no chats, no portals)

**Expected Result:**
- ✅ Friendly empty state message
- ✅ Icon/illustration shown
- ✅ Action button to add content (if applicable)

---

#### 9.3 Error States
**Steps:**
1. Simulate network error (disconnect internet)
2. Try to load a page
3. Observe error handling

**Expected Result:**
- ✅ Error message displayed
- ✅ Retry button available
- ✅ No app crash

---

#### 9.4 Animations & Transitions
**Steps:**
1. Navigate between pages
2. Open/close modals
3. Toggle sections

**Expected Result:**
- ✅ Smooth fade transitions
- ✅ Modal slide-up animation
- ✅ No janky animations
- ✅ Consistent timing (200-300ms)

---

#### 9.5 Responsive Design
**Steps:**
1. Resize browser window
2. Test on mobile viewport (375px, 414px)
3. Test on tablet viewport (768px)
4. Test on desktop (1024px+)

**Expected Result:**
- ✅ Layout adapts to screen size
- ✅ No horizontal scroll
- ✅ Touch targets large enough on mobile
- ✅ Text readable on all sizes

---

### **10. Security & Session Management** [P0]

#### 10.1 Protected Routes
**Steps:**
1. Logout completely
2. Try to access `/main`, `/profile/:id`, `/chat/dm/:id`
3. Should redirect to `/login`

**Expected Result:**
- ✅ All protected routes redirect to login
- ✅ No data exposed when not authenticated

---

#### 10.2 Token Expiration Handling
**Steps:**
1. Login successfully
2. Wait for JWT token to expire (or manually clear token in localStorage)
3. Try to make an API request

**Expected Result:**
- ✅ 401 error intercepted by axios
- ✅ User logged out automatically
- ✅ Redirected to login
- ✅ localStorage cleared

---

#### 10.3 CORS & API Communication
**Steps:**
1. Open browser DevTools → Network tab
2. Navigate around the app
3. Observe API requests

**Expected Result:**
- ✅ All requests include `Authorization: Bearer TOKEN` header
- ✅ CORS errors don't occur
- ✅ API responses successful

---

## 🐛 Bug Reporting

When you find a bug, please document it with this format:

### Bug Report Template
```markdown
**Title:** [Short description]

**Priority:** P0 / P1 / P2

**Steps to Reproduce:**
1. Step one
2. Step two
3. ...

**Expected Result:**
[What should happen]

**Actual Result:**
[What actually happens]

**Screenshots/Logs:**
[Attach if applicable]

**Environment:**
- Browser: Chrome 120 / Firefox 115 / Safari 17
- OS: Windows 11 / macOS 14 / etc.
- Backend URL: http://localhost:5000

**Additional Notes:**
[Any other context]
```

---

## ⚠️ Known Limitations

### Features NOT Implemented (by design):
1. **Public (non-authenticated) portal pages** - Coming in future phase
2. **Push notifications** - Web app uses Socket.IO for real-time updates instead
3. **Advanced analytics/metrics** - Basic features only
4. **Offline mode** - Requires active internet connection
5. **Mobile native features** - This is a web app, not a native mobile app

### Expected Backend Dependencies:
The following backend endpoints MUST exist and return proper responses:
- Authentication: `/api/register`, `/api/login`
- User: `/api/user/me`, `/api/user/:id`, `/api/user/notification_settings`
- Portal: `/api/portal/*`, `/api/search_portals`
- Goals: `/api/goals/*`, `/api/goals/pending_invites`
- Messaging: `/api/message/send_message`, `/api/message/get_messages`, `/api/message/group_chats`
- Payments: `/api/stripe/*`
- Search: `/api/search_people`, `/api/filter_people`

### Browser Compatibility:
- **Recommended:** Chrome 100+, Firefox 100+, Safari 15+, Edge 100+
- **May have issues:** IE11 (not supported), older mobile browsers

---

## ✅ Test Completion Checklist

Before signing off on testing, ensure:

- [ ] All P0 tests passed
- [ ] At least 80% of P1 tests passed
- [ ] Critical bugs documented and filed
- [ ] No app-breaking errors remain
- [ ] Authentication flow works end-to-end
- [ ] Major features (portals, goals, messaging) functional
- [ ] Payment flows work in Stripe test mode
- [ ] App performs reasonably (no severe lag)
- [ ] UI looks acceptable on desktop and mobile

---

## 📞 Support & Questions

If you encounter issues or have questions during testing:
1. Check browser console for errors (F12 → Console tab)
2. Check network tab for failed API requests (F12 → Network tab)
3. Verify backend server is running and accessible
4. Check `.env` file has correct `VITE_API_BASE_URL`

---

**Good luck with testing! 🚀**
