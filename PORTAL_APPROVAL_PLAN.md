# Portal Approval Workflow — Implementation Plan

## Status: PLANNED, NOT IMPLEMENTED

---

## Overview

New portals currently go live instantly (`status='active'`). This plan adds an admin approval step where new portals start as `status='pending'` and must be approved before becoming visible to all users.

**Key insight: No DB migration required.** The `Portal` model already has:
- `status = db.Column(db.String(32), default='active', index=True)` → use `'pending'` / `'active'` / `'rejected'`
- `visible = db.Column(db.Boolean, default=True)` → unchanged, used for user-controlled visibility

---

## What Changes (and What Doesn't)

### Status values
| Value | Meaning |
|-------|---------|
| `'active'` | Approved — visible to all (current default) |
| `'pending'` | Awaiting admin approval — hidden from public, visible to creator only |
| `'rejected'` | Denied — hidden from public, visible to creator only |

### Existing portals
All existing portals already have `status='active'` — they are completely unaffected.

---

## Backend Changes (4 files, minimal)

### 1. `Portal_Details.py` — Change creation default
**File:** `app/routes/Portal_Routes/Portal_Details.py`
**Line ~183:** In `api_create_portal()`, change:
```python
# BEFORE
status='active',

# AFTER
status='pending',
```
That's it for creation. New portals start as pending.

---

### 2. `Get_Portals.py` — Filter public listings by status
**File:** `app/routes/Portal_Routes/Get_Portals.py`

Two endpoints need filtering: `/portals` and `/filter_network_portals`.

In both endpoints, add a status filter **after the main query is built** but **before** `.offset().limit().all()`:

```python
# Add to both endpoints, just before the final .offset().limit():
# Show: active portals to all, OR pending/rejected portals only to their creator
query = query.filter(
    db.or_(
        Portal.status == 'active',
        Portal.users_id == user_id  # creator can always see their own portal
    )
)
```

This means:
- Regular users see only `active` portals in listings
- The creator can still see their own `pending` or `rejected` portal in their own profile/rep tab

---

### 3. `SearchPortals.py` — Filter search results
**File:** `app/routes/Portal_Routes/SearchPortals.py`

Same filter as above — add before results are returned:
```python
query = query.filter(
    db.or_(
        Portal.status == 'active',
        Portal.users_id == user_id
    )
)
```

---

### 4. `Public_Portals.py` — Filter public (unauthenticated) routes
**File:** `app/routes/public_web/Public_Portals.py`
**File:** `app/routes/public_web/Public_Portal_Details.py`

Public routes have no authenticated user, so filter strictly:
```python
query = query.filter(Portal.status == 'active')
```

For `Public_Portal_Details.py` — return 404 for pending/rejected portals:
```python
portal = Portal.query.filter_by(id=portal_id, status='active').first()
if not portal:
    return jsonify({'error': 'Portal not found'}), 404
```

---

### 5. New admin endpoint — `app/routes/Portal_Routes/Portal_Details.py` (or new file)
**New route:** `POST /api/portal/admin/approve`

This follows the exact same pattern as the Stripe Connect approval in `Payments.py`.

```python
@portal_bp.route('/admin/approve', methods=['POST'])
@jwt_required
def api_admin_approve_portal():
    """Admin-only endpoint to approve or reject a pending portal."""
    ADMIN_USER_IDS = [45]  # Add any additional admin user IDs here

    user_id = g.current_user.id
    if user_id not in ADMIN_USER_IDS:
        return jsonify({'error': 'Unauthorized'}), 403

    data = request.get_json()
    portal_id = data.get('portal_id')
    action = data.get('action')  # 'approve' or 'reject'

    if not portal_id or action not in ('approve', 'reject'):
        return jsonify({'error': 'portal_id and action (approve/reject) required'}), 400

    portal = Portal.query.filter_by(id=portal_id).first()
    if not portal:
        return jsonify({'error': 'Portal not found'}), 404

    if action == 'approve':
        portal.status = 'active'
    elif action == 'reject':
        portal.status = 'rejected'

    db.session.commit()

    # Optional: notify creator via DM
    # _notify_portal_decision(portal, action)

    return jsonify({
        'result': 'ok',
        'portal_id': portal_id,
        'status': portal.status
    })


@portal_bp.route('/admin/pending', methods=['GET'])
@jwt_required
def api_admin_pending_portals():
    """Admin-only: list all pending portals."""
    ADMIN_USER_IDS = [45]

    user_id = g.current_user.id
    if user_id not in ADMIN_USER_IDS:
        return jsonify({'error': 'Unauthorized'}), 403

    portals = Portal.query.filter_by(status='pending').order_by(Portal.created_at.asc()).all()
    return jsonify({'result': [p.as_card_dict() for p in portals]})
```

---

## Optional: Notify Creator via DM on Decision

Add a helper function (can live in `welcome_dm.py` or a new `portal_notifications.py`):

```python
def notify_portal_decision(db, socketio, portal, action):
    """Send a DM to the portal creator when their portal is approved or rejected."""
    from app.models.People_Models.Messaging_Models.Direct_Messages import DirectMessage
    from datetime import datetime

    sender_id = 45  # From admin/founder account
    recipient_id = portal.users_id

    if action == 'approve':
        text = (
            f"Great news! Your portal \"{portal.name}\" has been approved and is now live on Rep. "
            f"Congratulations — go share it!"
        )
    else:
        text = (
            f"Your portal \"{portal.name}\" was not approved at this time. "
            f"Please message me directly if you have questions."
        )

    msg = DirectMessage(
        sender_id=sender_id,
        recipient_id=recipient_id,
        text=text,
        created_at=datetime.utcnow()
    )
    db.session.add(msg)
    db.session.commit()
    # emit socket notification here (same pattern as welcome_dm.py)
```

---

## Web App Admin UI (minimal)

A simple hidden admin page in the Vue web app. No new nav item needed — access via direct URL.

**New file:** `web-app/src/pages/Admin/PortalApproval.vue`

**What it shows:**
- List of all pending portals (fetches `GET /api/portal/admin/pending`)
- For each portal: name, creator, created_at, about preview
- Two buttons: **Approve** / **Reject** (calls `POST /api/portal/admin/approve`)
- Simple, no styling required beyond functional

**Route:** `/admin/portals` (add to Vue router, no nav link needed)

---

## What the Creator Sees

When a user creates a portal:
1. Portal is created normally — they get the full portal card back from the API
2. They can see it in their own rep tab (because `users_id == current_user`)
3. It does NOT appear in public listings or search
4. Optional: Show a "Pending Approval" badge in the iOS/web portal card when `status == 'pending'`
5. When approved/rejected, they receive a DM notification

---

## iOS Changes (optional, cosmetic only)

In `PortalPage.swift` / portal card views, check `portal.status` and show a subtle badge:

```swift
if portal.status == "pending" {
    Text("Pending Approval")
        .font(.caption)
        .foregroundColor(.orange)
}
```

No functional changes needed on iOS — the backend handles all filtering.

---

## Activation Steps (code is already written — just uncomment)

All code is in place and commented out. To go live, make exactly these edits:

---

### Step 1 — `Portal_Details.py` · Portal creation
**File:** `app/routes/Portal_Routes/Portal_Details.py` (~line 186)

Comment out `status='active'` and uncomment `status='pending'`:
```python
# status='pending',   ← uncomment this
status='active',      ← comment this out
```

---

### Step 2 — `Portal_Details.py` · Admin routes
**File:** `app/routes/Portal_Routes/Portal_Details.py` (bottom of file, ~line 549)

Uncomment the `ADMIN_USER_IDS` variable (pick one form):
```python
ADMIN_USER_IDS = [45]
# OR, to load from environment variable:
# ADMIN_USER_IDS = [int(x) for x in os.environ.get('ADMIN_USER_IDS', '45').split(',')]
```

Then uncomment both route functions: `api_admin_pending_portals` and `api_admin_approve_portal`.
Remove the `#` from every line of both functions, including the `@portal_bp.route` and `@jwt_required` decorators.

---

### Step 3 — `Get_Portals.py` · Authenticated listings (2 places)
**File:** `app/routes/Portal_Routes/Get_Portals.py`

There are two identical commented blocks — one in `api_get_portals()` and one in `filter_network_portals()`. Uncomment both:
```python
query = query.filter(
    db.or_(Portal.status == 'active', Portal.users_id == user_id)
)
```
This lets the creator always see their own pending/rejected portals but hides them from everyone else.

---

### Step 4 — `SearchPortals.py` · Search results
**File:** `app/routes/Portal_Routes/SearchPortals.py` (~line 35)

Uncomment this line inside the existing `.filter()` call:
```python
Portal.status == 'active',
```

---

### Step 5 — `Public_Portals.py` · Public listing
**File:** `app/routes/public_web/Public_Portals.py` (~line 58)

Uncomment this line inside the existing `.filter()` call:
```python
Portal.status == 'active',
```

---

### Step 6 — `Public_Portal_Details.py` · Public portal page
**File:** `app/routes/public_web/Public_Portal_Details.py` (~line 124)

Uncomment these two lines:
```python
if portal.status != 'active':
    return jsonify({'error': "Portal not found"}), 404
```

---

### Step 7 — Web app admin UI
Create `web-app/src/pages/Admin/PortalApproval.vue` (new file) and add a route at `/admin/portals` in the Vue router. The page should:
- Fetch `GET /api/portal/admin/pending` to list pending portals
- Call `POST /api/portal/admin/approve` with `{ portal_id, action: 'approve'|'reject' }` on button click

---

### Step 8 — (Optional) DM notification to creator
In the admin approve route, after `db.session.commit()`, call the `notify_portal_decision()` helper described above to send the creator a DM.

---

### Step 9 — (Optional) iOS "Pending" badge
In portal card views, show a badge when `portal.status == "pending"`:
```swift
if portal.status == "pending" {
    Text("Pending Approval").font(.caption).foregroundColor(.orange)
}
```

---

## Full Backend Review — Files Checked

All 14 backend files that query the Portal model were reviewed. Here's the verdict:

| File | Risk | Notes |
|------|------|-------|
| `Portal_Details.py` | ✅ Covered | Creation + admin routes handled |
| `Get_Portals.py` | ✅ Covered | Both endpoints have commented filters |
| `SearchPortals.py` | ✅ Covered | Filter in place (commented) |
| `Public_Portals.py` | ✅ Covered | Filter in place (commented) |
| `Public_Portal_Details.py` | ✅ Covered | Status check in place (commented) |
| `EditUser.py` | ✅ No issue | Only deletes portals on account deletion |
| `FlagPortal.py` | ✅ No issue | Verifies portal exists by ID — requires knowing the ID; no data exposed |
| `Goal_Details.py` | ✅ No issue | Auth-gated; operates on portals user has access to |
| `Payments.py` | ✅ No issue | Stripe Connect admin approval is separate from portal approval |
| `SharePortalViaMessage.py` | ✅ No issue | Auth-gated; users sharing by direct ID is acceptable |
| `SendGroupChat.py` | ✅ No issue | Auth-gated; lookup only for permission checks |
| `SendDirectMessage.py` | ✅ No issue | Auth-gated; lookup only for permission checks |
| `Public_Goal_Details.py` | ⚠️ Edge case | See below |
| `Public_Payments.py` | ⚠️ Edge case | See below |

### Edge Case 1 — `Public_Goal_Details.py`
`/public/goal/<goal_id>` is a public unauthenticated endpoint. It fetches the goal and then reads `portal.name` to include in the response. If a goal belongs to a pending portal, the goal detail page is still publicly accessible and includes the portal's name.

**Impact:** Low. An outsider would need to know the specific `goal_id` to reach this. Only the portal name leaks, not full portal details.

**Decision:** Acceptable as-is. If stricter enforcement is needed, add a portal status check to `Public_Goal_Details.py` similar to what's in `Public_Portal_Details.py`. Not included in the current plan.

### Edge Case 2 — `Public_Payments.py`
`/public/create_checkout_session` accepts a `portal_id` and attempts to send a Stripe payment to it. A pending portal could technically receive a payment if it had `stripe_account_id` set.

**Impact:** None in practice. Pending portals won't have `stripe_account_id` — that requires separate Stripe Connect admin approval which is its own gated process. The payment route already validates `portal.stripe_account_id` exists before proceeding.

**Decision:** No action needed.

---

## Rollback Plan

If this needs to be reverted after activation:
- Re-comment all uncommented lines above (Steps 1–6)
- All existing portals already have `status='active'` — no data cleanup needed
- No DB migration to undo

---

## Admin User IDs

Current admin users: `[45]` (Adam / founder account)
To add more admins, add their user IDs to the `ADMIN_USER_IDS` list in Step 2.
