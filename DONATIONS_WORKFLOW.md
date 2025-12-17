# Donations Workflow Documentation

**Last Updated:** December 17, 2025
**Status:** Production (Apple App Store Compliant)
**Implementation Type:** Frontend-Only (Phase 1)

---

## Overview

This document describes the donations workflow implementation for Rep's iOS app, designed to comply with Apple App Store requirements while supporting nonprofit fundraising.

### Key Design Decisions

1. **Frontend-Only Implementation (Phase 1)**: "Donations" is a display-only goal type in the frontend, stored as "Fund" in the backend
2. **Mandatory Disclosure**: Users must acknowledge tax-deductibility warnings before donating
3. **External Browser**: Donations open in Safari (not in-app) per Apple requirements
4. **Separation from Payments**: Regular crowdfunding ("Fund" goals) uses standard payment flow without disclosure

---

## Current Implementation

### Goal Types

| Display Name (Frontend) | Stored As (Backend) | Transaction Type | Disclosure Required | Browser |
|-------------------------|---------------------|------------------|---------------------|---------|
| **Donations** | Fund | `donation` | ✅ Yes | 🌐 Safari |
| **Fund** | Fund | `payment` | ❌ No | 📱 In-app |
| **Sales** | Sales | `payment` | ❌ No | 📱 In-app |

### How It Works

**Backend:**
- Both "Donations" and "Fund" goals are stored as `goal_type = "Fund"`
- No backend distinction between nonprofit donations and crowdfunding
- Both update goal progress identically

**Frontend:**
- User selects "Donations" from goal creation form
- `Edit_Goal.swift` maps "Donations" → "Fund" before API call (lines 167-168)
- Goals are stored with `goal_type = "Fund"` but display as "Donations" in app
- Checks `goal.typeName == "Donations"` to trigger special workflow
- "Donations" goals → Disclosure + External Safari
- "Fund" goals → Standard payment flow

---

## Donations User Flow

### Step 1: User Initiates Donation
**Files:** `GoalsDetailView.swift:430` or `PortalPage.swift:407`

```swift
transactionType: goal.typeName == "Donations" ? .donation : .payment
```

User clicks "Support" on a goal with `typeName = "Donations"`.

### Step 2: Payment Sheet Opens
**File:** `PayTransaction.swift`

Shows donation-specific UI:
- Title: "Donate"
- Amount label: "Donation Amount"
- Button: "Donate $X"

### Step 3: Disclosure Appears
**File:** `DonationDisclosureView.swift`

Mandatory disclosure sheet with:
- Portal and goal information
- ⚠️ **Warning**: "Rep does not verify tax-exempt status"
- **Requirement**: "Consult your tax advisor"
- User must click "I Understand - Continue to Donation"

**Compliance Note:** This step is critical for Apple App Store approval.

### Step 4: Stripe Checkout Created
**File:** `PayTransaction.swift:336-339`

After user accepts disclosure:
1. Sets `donationDisclosureAccepted = true`
2. Creates Stripe checkout session
3. Backend sends `transaction_type: "donation"`

### Step 5: Opens in Safari
**File:** `PayTransaction.swift:515-520`

```swift
if self.transactionType == .donation {
    UIApplication.shared.open(url)  // Opens Safari
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        self.dismiss()  // Closes payment sheet
    }
}
```

**Why Safari?** Apple requires clear indication of external financial transactions.

### Step 6: Payment Completes
User completes payment in Safari, then returns to app via deep link.

---

## Apple App Store Compliance

### Requirements Met

✅ **Disclosure Before Payment**: Mandatory acknowledgment screen
✅ **No False Tax Claims**: Explicitly states Rep doesn't verify tax-exempt status
✅ **External Browser**: Opens in Safari (not in-app webview)
✅ **Clear Language**: No ambiguity about donation vs payment vs purchase
✅ **User Acknowledgment**: Must click "I Understand" to proceed

### Key Language

From `DonationDisclosureView.swift`:

> "Rep does not verify the tax-exempt status of organizations on this platform. This donation may not be tax-deductible. Please consult your tax advisor to determine if this donation qualifies for a tax deduction."

---

## Files Modified

### Frontend (Swift)

| File | Change | Lines |
|------|--------|-------|
| `DonationDisclosureView.swift` | **NEW** - Disclosure screen | All |
| `PayTransaction.swift` | Re-enabled `.donation` enum, added disclosure logic | 13-70, 110-112, 207-215, 332-346, 515-520 |
| `GoalsDetailView.swift` | Check for "Donations" type | 430 |
| `PortalPage.swift` | Check for "Donations" type | 407 |
| `PortalPaymentSetup.swift` | Re-added "donations" to language | 300 |

### Backend (Python)

**No changes required** - Backend treats "Donations" and "Fund" identically as `goal_type = "Fund"`.

---

## Testing Checklist

### Donations Workflow
- [ ] Create goal with `typeName = "Donations"`
- [ ] Click "Support" button
- [ ] Verify disclosure appears
- [ ] Click "Cancel" - should close without payment
- [ ] Click "I Understand" - should proceed
- [ ] Verify opens in Safari (not in-app)
- [ ] Complete payment in Safari
- [ ] Verify return to app works
- [ ] Check goal progress updated

### Regular Fund Workflow
- [ ] Create goal with `typeName = "Fund"`
- [ ] Click "Support" button
- [ ] Verify NO disclosure appears
- [ ] Verify opens in-app webview (not Safari)
- [ ] Complete payment
- [ ] Check goal progress updated

### Edge Cases
- [ ] Rapidly switching between donation and payment goals
- [ ] User backgrounds app during disclosure
- [ ] Safari payment timeout/cancellation
- [ ] No internet during disclosure acknowledgment

---

## Future Backend Updates (Phase 2)

**When:** After Apple App Store approval

### Database Schema Changes

**1. Add "Donations" as Distinct Goal Type**

```python
# In Goal model or validation
ALLOWED_GOAL_TYPES = ['Fund', 'Sales', 'Donations']
```

**Benefits:**
- Separate reporting for nonprofit donations vs crowdfunding
- Can add donation-specific features (tax receipt generation, etc.)
- Clearer data model

### API Changes Needed

**File:** `app/routes/User_Routes/Payments.py`

**Change 1: Update Goal Progress Logic** (Line 353)

```python
# Current
if goal and goal.goal_type in ['Fund', 'Sales']:

# Change to
if goal and goal.goal_type in ['Fund', 'Sales', 'Donations']:
```

**Change 2: Optional - Add Validation**

```python
# Validate transaction_type matches goal_type
if goal.goal_type == 'Donations' and transaction_type != 'donation':
    return jsonify({'error': 'Donations goals require transaction_type=donation'}), 400
```

### Migration Script

```python
# migrations/versions/add_donations_goal_type.py

def upgrade():
    # No data migration needed - existing "Fund" goals remain as-is
    # New "Donations" goals will be created with proper type
    pass

def downgrade():
    # Convert any "Donations" goals back to "Fund"
    op.execute("""
        UPDATE goals
        SET goal_type = 'Fund'
        WHERE goal_type = 'Donations'
    """)
```

### Frontend Updates (Phase 2)

**Remove Temporary Comments**

In `GoalsDetailView.swift` and `PortalPage.swift`, update comments:

```swift
// Current comment:
// Only "Donations" type goals trigger disclosure workflow (stored as "Fund" in backend)

// Phase 2 comment:
// Donations goals trigger disclosure workflow
transactionType: goal.typeName == "Donations" ? .donation : .payment
```

### Database Reports/Analytics

Once backend distinguishes "Donations" from "Fund", you can:

```sql
-- Total donations by portal
SELECT
    p.name AS portal_name,
    SUM(t.amount/100) AS total_donations
FROM transactions t
JOIN goals g ON t.goal_id = g.id
JOIN portals p ON t.portal_id = p.id
WHERE g.goal_type = 'Donations'
GROUP BY p.id;

-- Nonprofit vs crowdfunding breakdown
SELECT
    goal_type,
    COUNT(*) AS goal_count,
    SUM(filled_quota) AS total_raised
FROM goals
WHERE goal_type IN ('Donations', 'Fund')
GROUP BY goal_type;
```

---

## Optional Future Enhancements

### Phase 3: Tax-Exempt Verification (If Desired)

**Add to Portal Model:**

```python
class Portal(db.Model):
    # ... existing fields ...
    is_tax_exempt = db.Column(db.Boolean, default=False)
    ein_number = db.Column(db.String(20), nullable=True)  # IRS EIN
    nonprofit_type = db.Column(db.String(50), nullable=True)  # "501c3", etc.
    tax_exempt_verified = db.Column(db.Boolean, default=False)
    tax_exempt_verified_at = db.Column(db.DateTime, nullable=True)
```

**Update Disclosure to Show EIN:**

```swift
if portal.isTaxExempt {
    Text("This organization self-identifies as tax-exempt.")
    if let ein = portal.einNumber {
        Text("EIN: \(ein)")
    }
    Text("Rep does not verify tax-exempt status. Verify on IRS.gov and consult your tax advisor.")
}
```

**Add IRS Lookup Button:**

```swift
Button("Verify on IRS.gov") {
    if let ein = portal.einNumber {
        let url = "https://apps.irs.gov/app/eos/"
        UIApplication.shared.open(URL(string: url)!)
    }
}
```

### Phase 4: Tax Receipt Generation

- Auto-generate PDF receipts for donations
- Include EIN, donation amount, date
- Email to donor
- Store in user's payment history

---

## Rollback Plan

If issues arise, to revert to payment-only workflow:

**Frontend:**

```swift
// In GoalsDetailView.swift and PortalPage.swift
transactionType: .payment  // Always use payment
```

**Comment out disclosure:**

```swift
// .sheet(isPresented: $showDonationDisclosure) { ... }
```

**Backend:** No changes needed (already treats everything as Fund)

---

## Support & Questions

**Technical Lead:** Adam Novak
**Implementation Date:** December 17, 2025
**Apple Review Status:** Submitted

For questions about this implementation, see:
- `DonationDisclosureView.swift` - Disclosure UI
- `PayTransaction.swift` - Payment flow logic
- This document - Overall architecture

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Dec 17, 2025 | Initial implementation - Frontend only |
| TBD | Future | Phase 2 - Backend "Donations" goal type |
