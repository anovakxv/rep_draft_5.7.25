# UX Improvement Recommendations - Rep iOS App

**Date:** December 24, 2025
**App Vision:** People-Purpose-Value accelerator - A purpose-driven rolodex designed to help networks identify top priorities for acceleration and guide people toward real-world action and in-person collaboration.

---

## 🔴 HIGH PRIORITY (Critical Usability Issues)

### 1. Make People/Portal Toggle Discoverable

**Current Issue:**
The REP logo button (bottom-right) toggles between People and Portals views, but this is completely hidden - users have no way to know this exists.

**File Location:**
`my-ios-app/Swift FrontEnd/Rep/MainScreen.swift`

**Current Implementation:**
- Lines 1625-1650: REP logo button toggles `page` state between `.people` and `.portals`
- Line 867-871: Page enum definition

```swift
// Current code - lines 1625-1650
.overlay(alignment: .bottomTrailing) {
    Button(
        action: {
            page = page == .people ? .portals : .people
            // ... fetch logic
        },
        label: {
            Image("REPLogo")
                .resizable()
                .scaledToFill()
                .frame(width: 44.0, height: 44.0)
        }
    )
    .padding(.trailing, 36)
    .padding(.bottom, 12)
}
```

**Recommended Solutions:**

**Option A (Recommended):** Replace REP logo with labeled segmented control
```swift
// Suggested implementation
HStack {
    Spacer()
    Picker("View Type", selection: $page) {
        Text("People").tag(MainScreen.Page.people)
        Text("Portals").tag(MainScreen.Page.portals)
    }
    .pickerStyle(.segmented)
    .frame(width: 200)
    Spacer()
}
.padding(.bottom, 12)
```

**Option B:** Add chevron icons and labels beside REP logo
```swift
HStack(spacing: 8) {
    Image(systemName: "chevron.left")
    Text(page == .people ? "People" : "Portals")
        .font(.caption)
    Image("REPLogo")
        .resizable()
        .frame(width: 44, height: 44)
    Text(page == .people ? "Portals" : "People")
        .font(.caption)
    Image(systemName: "chevron.right")
}
```

**Option C:** Swipeable view with page indicators
- Implement `TabView` with page style
- Add `.tabViewStyle(.page(indexDisplayMode: .always))`

**Impact:** Critical - Core navigation is currently invisible
**Effort:** Medium
**Alignment:** Makes the "Rolodex" aspect clear - browsing people vs purposes

---

### 2. Clarify Tab Labels for First-Time Users

**Current Issue:**
"Network" and "Purpose" are abstract terms. New users won't immediately understand what these mean.

**File Location:**
`my-ios-app/Swift FrontEnd/Rep/MainScreen.swift`

**Current Implementation:**
- Line 1829: `segments: ["Chats", "Network", "Purpose"]`
- Lines 813-863: `MainSegmentedPicker` struct

**Recommended Changes:**

**Option A (Clear & Specific):**
```swift
segments: ["Chats", "My Network", "Purposes"]
```

**Option B (Icon-focused):**
```swift
// Add icons to segments
segments: [
    ("💬", "Chats"),
    ("👥", "Network"),
    ("🎯", "Purposes")
]
```

**Add First-Time Tooltips:**
Create new file: `my-ios-app/Swift FrontEnd/Rep/Components/TabTooltipView.swift`

```swift
struct TabTooltipView: View {
    let message: String
    @Binding var isShowing: Bool

    var body: some View {
        if isShowing {
            VStack {
                Text(message)
                    .font(.caption)
                    .padding(8)
                    .background(Color.black.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                Image(systemName: "arrowtriangle.down.fill")
                    .foregroundColor(.black)
            }
        }
    }
}
```

**Tooltip Messages:**
- **Chats:** "Messages & Goal Team invites"
- **My Network:** "People you're connected with + their priorities"
- **Purposes:** "All community priorities (organizations, initiatives, missions)"

**Storage:**
```swift
@AppStorage("hasSeenTabTooltips") private var hasSeenTabTooltips: Bool = false
```

**Impact:** High - Helps users understand navigation structure
**Effort:** Low (label change), Medium (with tooltips)
**Alignment:** Makes People-Purpose structure immediately clear

---

### 3. Redesign Action Sheet for Clarity

**Current Issue:**
The "+" action sheet mixes settings ("Show All/Safe") with actions ("Add Purpose", "Team Chat"). Confusing hierarchy.

**File Location:**
`my-ios-app/Swift FrontEnd/Rep/MainScreen.swift`

**Current Implementation:**
- Lines 1690-1771: Action sheet with mixed settings and actions
- Lines 1692-1742: "Show All/Safe" toggle
- Lines 1744-1763: Action buttons

**Recommended Solution - Split into Two Menus:**

**1. Keep "+" button for CREATE actions only:**

Modify lines 1690-1771:
```swift
case .actionSheet:
    VStack(spacing: 24) {
        // REMOVE the "Show All/Safe" section

        Button(action: {
            pendingAction = .addPurpose
            activeSheet = nil
        }) {
            Text("Add Purpose")
                .foregroundColor(Color.repGreen)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.vertical, 12)
        }

        Button(action: {
            pendingAction = .teamChat
            activeSheet = nil
        }) {
            Text("Create Team Chat")  // Changed from "Team Chat"
                .foregroundColor(Color.repGreen)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.vertical, 12)
        }

        // Optional: Add "Join Goal Team" action
        Button(action: {
            // Navigate to goal team browser
            activeSheet = nil
        }) {
            Text("Join Goal Team")
                .foregroundColor(Color.repGreen)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.vertical, 12)
        }

        Button(action: { activeSheet = nil }) {
            Text("Cancel")
                .foregroundColor(.secondary)
                .padding(.vertical, 12)
        }
    }
    .padding()
    .presentationDetents([.medium])
```

**2. Add new FILTER button for settings:**

Add to toolbar (lines 1862-1895):
```swift
ToolbarItem(placement: .topBarTrailing) {
    HStack(spacing: 16) {
        // Add filter button BEFORE search
        Button(
            action: { mainActiveSheet = .filterSettings },
            label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: MainScreen.Constants.imageSize/1.5,
                        height: MainScreen.Constants.imageSize/1.5
                    )
                    .foregroundColor(Color.repGreen)
            }
        )

        Button(action: { /* existing search */ }) { /* ... */ }
        Button(action: { showActionSheet() }) { /* ... */ }
    }
}
```

**3. Add new filter sheet:**

Add to ActiveSheet enum (line 1489):
```swift
enum ActiveSheet: Identifiable {
    case actionSheet
    case addPurpose
    case filterSettings  // NEW

    var id: Int {
        switch self {
        case .actionSheet: return 1
        case .addPurpose: return 2
        case .filterSettings: return 3  // NEW
        }
    }
}
```

Add filter sheet view (after line 1771):
```swift
case .filterSettings:
    VStack(spacing: 24) {
        Text("Filter Options")
            .font(.headline)
            .padding(.top)

        HStack(spacing: 24) {
            Text("Show:")
                .font(.body)
                .fontWeight(.regular)
                .foregroundColor(.secondary)

            Button(action: {
                showOnlySafePortals = false
                portalsVM.fetchPortals(userId: userId, section: section, safeOnly: false)
            }) {
                HStack {
                    ZStack {
                        Circle()
                            .stroke(Color.secondary, lineWidth: 2)
                            .frame(width: 20, height: 20)
                        if !showOnlySafePortals {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                                .font(.system(size: 14, weight: .bold))
                        }
                    }
                    Text("All Content")  // Changed from "All"
                        .font(.body)
                        .fontWeight(!showOnlySafePortals ? .bold : .regular)
                }
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: {
                showOnlySafePortals = true
                portalsVM.fetchPortals(userId: userId, section: section, safeOnly: true)
            }) {
                HStack {
                    ZStack {
                        Circle()
                            .stroke(Color.secondary, lineWidth: 2)
                            .frame(width: 20, height: 20)
                        if showOnlySafePortals {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                                .font(.system(size: 14, weight: .bold))
                        }
                    }
                    Text("Family-Friendly")  // Changed from "Safe"
                        .font(.body)
                        .fontWeight(showOnlySafePortals ? .bold : .regular)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }

        Button(action: { activeSheet = nil }) {
            Text("Done")
                .foregroundColor(Color.repGreen)
                .fontWeight(.bold)
                .padding(.vertical, 12)
        }
    }
    .padding()
    .presentationDetents([.medium])
```

**Impact:** High - Clarifies purpose of "+" button (create actions)
**Effort:** Medium
**Alignment:** Emphasizes ACTION - "What can I DO to accelerate purposes?"

---

### 4. Improve Empty States with Clear CTAs

**Current Issue:**
Empty states just say "No portals found" or "No people found" - no guidance on what to do next.

**File Location:**
`my-ios-app/Swift FrontEnd/Rep/MainScreen.swift`

**Current Implementation:**
- Line 1596-1597: "No portals found" message
- Line 1577-1578: "No members of your network yet..." message
- Line 1565-1568: "No chats found" message

**Recommended Solution:**

Create new component file: `my-ios-app/Swift FrontEnd/Rep/Components/EmptyStateView.swift`

```swift
import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    let primaryAction: EmptyStateAction?
    let secondaryAction: EmptyStateAction?

    struct EmptyStateAction {
        let title: String
        let action: () -> Void
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)

            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if let primary = primaryAction {
                Button(action: primary.action) {
                    Text(primary.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Color.repGreen)
                        .cornerRadius(10)
                }
                .padding(.top, 8)
            }

            if let secondary = secondaryAction {
                Button(action: secondary.action) {
                    Text(secondary.title)
                        .font(.subheadline)
                        .foregroundColor(Color.repGreen)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

**Update MainScreen.swift:**

Replace line 1596-1603 (Portals empty state):
```swift
EmptyStateView(
    icon: "target",
    title: section == 1 ? "Build Your Network" : "No Purposes Found",
    description: section == 1
        ? "Connect with people working on purposes you care about"
        : "Try adjusting your search or filters",
    primaryAction: section == 1
        ? EmptyStateView.EmptyStateAction(
            title: "Browse Purposes",
            action: {
                section = 2
                portalsVM.fetchPortals(userId: userId, section: 2, safeOnly: showOnlySafePortals)
            }
        )
        : nil,
    secondaryAction: EmptyStateView.EmptyStateAction(
        title: "Search",
        action: { showSearch = true }
    )
)
```

Replace line 1577-1584 (People empty state):
```swift
EmptyStateView(
    icon: "person.2",
    title: "Build Your Network",
    description: "View profiles and tap +NTWK to connect with people",
    primaryAction: EmptyStateView.EmptyStateAction(
        title: "Browse Purposes",
        action: {
            page = .portals
            section = 2
        }
    ),
    secondaryAction: EmptyStateView.EmptyStateAction(
        title: "Search People",
        action: { showSearch = true }
    )
)
```

Replace line 1565-1575 (Chats empty state):
```swift
EmptyStateView(
    icon: "message.badge",
    title: "No Active Chats",
    description: "Start a conversation or join a goal team to get started",
    primaryAction: EmptyStateView.EmptyStateAction(
        title: "Browse Network",
        action: { section = 1 }
    ),
    secondaryAction: nil
)
```

**Impact:** High - Guides users toward action when lists are empty
**Effort:** Medium
**Alignment:** Encourages real-world connection and action

---

### 5. Simplify Goal Team Joining Flow from Portal Page

**Current Issue:**
Users cannot directly join a Goal Team from the Portal Page action menu. The current flow is confusing and requires too many steps:

**Current Flow (Too Many Steps):**
1. User on Portal Page → taps "+" action button (bottom)
2. Action sheet shows "Select Goal Team" option
3. User taps "Select Goal Team" → **This just dismisses the sheet** (activeSheet = nil)
4. User sees Goal Teams list (which was already visible on the page)
5. User must figure out to tap a Goal Team tile
6. Opens GoalsDetailView
7. User taps "+" action button AGAIN
8. Finally can tap "Join Team"

**Problem:** "Select Goal Team" doesn't actually help - it just closes the menu and shows what was already visible. Users need 2+ extra clicks and must navigate through two different action sheets to join a team.

**File Locations:**
- `my-ios-app/Swift FrontEnd/Rep/PortalPage.swift`
- `my-ios-app/Swift FrontEnd/Rep/GoalsDetailView.swift`

**Current Implementation:**

**PortalPage.swift (Lines 275-283):**
```swift
Button(action: {
    activeSheet = nil  // Just dismisses - doesn't help user!
}) {
    Text("Select Goal Team")
        .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
        .font(.title2)
        .fontWeight(.bold)
        .padding(.vertical, 5)
}
```

**GoalsDetailView.swift (Lines 272-288):**
```swift
// "Join Team" is only available AFTER navigating to individual goal
if !isOnTeam && !isCreator {
    Button(action: {
        viewModel.joinRecruitingGoal(goalId: viewModel.goal.id) { success in
            activeSheet = nil
            if success {
                viewModel.load(goalId: viewModel.goal.id)
            }
        }
    }) {
        Text("Join Team")
            // ... styling
    }
}
```

---

**Recommended Solutions:**

### **Option A (Recommended): In-Sheet Goal Picker with Instant Join**

Replace "Select Goal Team" with a scrollable goal picker right in the action sheet.

**Implementation:**

1. **Add new enum case** for goal picker sheet:
```swift
// Add to PortalPage.swift SheetType enum
enum SheetType: Identifiable {
    case addGoal
    case portalActionMenu
    case goalPicker  // NEW

    var id: Int {
        switch self {
        case .addGoal: return 1
        case .portalActionMenu: return 2
        case .goalPicker: return 3  // NEW
        }
    }
}
```

2. **Replace "Select Goal Team" button** (lines 275-283):
```swift
Button(action: {
    activeSheet = .goalPicker  // Open goal picker sheet
}) {
    HStack {
        Text("Join Goal Team")
            .foregroundColor(Color.repGreen)
            .font(.title2)
            .fontWeight(.bold)
        Spacer()
        Image(systemName: "chevron.right")
            .foregroundColor(Color.repGreen)
    }
    .padding(.vertical, 5)
}
```

3. **Add Goal Picker Sheet view** (add after line 326):
```swift
case .goalPicker:
    GoalPickerSheet(
        goals: viewModel.portalGoals.filter { $0.typeName == "Recruiting" },
        currentUserId: userId,
        onJoin: { goalId in
            joinGoalTeam(goalId: goalId)
            activeSheet = nil
        },
        onViewDetails: { goal in
            // Navigate to GoalsDetailView
            selectedGoal = goal
            navigateToGoalDetails = true
            activeSheet = nil
        },
        onCancel: {
            activeSheet = .portalActionMenu  // Back to main menu
        }
    )
```

4. **Create GoalPickerSheet component** (new section in PortalPage.swift):
```swift
// MARK: - Goal Picker Sheet

struct GoalPickerSheet: View {
    let goals: [Goal]
    let currentUserId: Int
    let onJoin: (Int) -> Void
    let onViewDetails: (Goal) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onCancel) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color.repGreen)
                    Text("Back")
                        .foregroundColor(Color.repGreen)
                }
                Spacer()
                Text("Join Goal Team")
                    .font(.headline)
                Spacer()
                // Spacer for symmetry
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .foregroundColor(Color.repGreen)
                }
            }
            .padding()

            Divider()

            // Goal List
            ScrollView {
                if goals.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.5))
                            .padding(.top, 40)
                        Text("No Goal Teams Available")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Check back later for new opportunities")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    VStack(spacing: 0) {
                        ForEach(goals) { goal in
                            GoalPickerRow(
                                goal: goal,
                                currentUserId: currentUserId,
                                onJoin: { onJoin(goal.id) },
                                onViewDetails: { onViewDetails(goal) }
                            )
                            Divider()
                        }
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

struct GoalPickerRow: View {
    let goal: Goal
    let currentUserId: Int
    let onJoin: () -> Void
    let onViewDetails: () -> Void

    // Check if user is already on team (you'll need to pass team member data)
    // For now, simplified
    private var isOnTeam: Bool {
        // TODO: Check if currentUserId is in goal's team members
        false
    }

    private var isCreator: Bool {
        goal.creatorId == currentUserId
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)

                    if !goal.subtitle.isEmpty {
                        Text(goal.subtitle)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    // Progress bar
                    HStack(spacing: 8) {
                        ProgressView(value: goal.progress, total: 1.0)
                            .tint(Color.repGreen)
                            .frame(height: 4)
                        Text("\(Int(goal.progressPercent))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Action buttons
                VStack(spacing: 8) {
                    if !isOnTeam && !isCreator {
                        Button(action: onJoin) {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                Text("Join")
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.repGreen)
                            .cornerRadius(8)
                        }
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.repGreen)
                            Text(isCreator ? "Creator" : "Member")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.repGreen)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.repGreen.opacity(0.1))
                        .cornerRadius(8)
                    }

                    Button(action: onViewDetails) {
                        Text("Details")
                            .font(.caption)
                            .foregroundColor(Color.repGreen)
                    }
                }
            }
        }
        .padding()
        .contentShape(Rectangle())
    }
}
```

5. **Add join function** to PortalPage.swift:
```swift
// Add to PortalPage main view
@State private var selectedGoal: Goal?
@State private var navigateToGoalDetails = false

private func joinGoalTeam(goalId: Int) {
    // Call API to join goal team
    // This is the same logic as in GoalsDetailView.swift line 275
    Task {
        do {
            guard let url = URL(string: "https://rep-june2025.onrender.com/api/goals/join_team") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")

            let body: [String: Any] = ["goals_id": goalId, "users_id": userId]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                // Success - refresh portal goals
                await MainActor.run {
                    viewModel.fetchPortalGoals(portalId: portalId)
                }
            }
        } catch {
            print("Error joining goal team: \(error)")
        }
    }
}

// Add navigation destination
.navigationDestination(isPresented: $navigateToGoalDetails) {
    if let goal = selectedGoal {
        GoalsDetailView(initialGoal: goal)
    }
}
```

**Benefits:**
- ✅ One-tap join from Portal page
- ✅ See all goals at once with progress
- ✅ Option to view details if needed
- ✅ Clear visual feedback (already a member, creator, etc.)
- ✅ Reduces clicks from 8+ to 2-3

---

### **Option B: Show Top Goal Teams Inline in Action Sheet**

Show top 3 recruiting goals directly as buttons in the Portal action sheet.

**Implementation:**

Replace "Select Goal Team" button with dynamic goal list:
```swift
// Instead of "Select Goal Team", show top recruiting goals
let recruitingGoals = viewModel.portalGoals.filter { $0.typeName == "Recruiting" }.prefix(3)

ForEach(Array(recruitingGoals)) { goal in
    Button(action: {
        joinGoalTeam(goalId: goal.id)
        activeSheet = nil
    }) {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Join: \(goal.title)")
                    .foregroundColor(Color.repGreen)
                    .font(.title3)
                    .fontWeight(.bold)
                if !goal.subtitle.isEmpty {
                    Text(goal.subtitle)
                        .foregroundColor(.secondary)
                        .font(.caption)
                        .lineLimit(1)
                }
            }
            Spacer()
            Image(systemName: "person.badge.plus")
                .foregroundColor(Color.repGreen)
        }
        .padding(.vertical, 5)
    }
}

// Show "View All Goal Teams" if more than 3
if viewModel.portalGoals.filter({ $0.typeName == "Recruiting" }).count > 3 {
    Button(action: {
        activeSheet = .goalPicker  // Open full picker
    }) {
        HStack {
            Text("View All Goal Teams")
                .foregroundColor(Color.repGreen)
                .font(.body)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(Color.repGreen)
        }
        .padding(.vertical, 5)
    }
}
```

**Benefits:**
- ✅ Immediate join for top goals
- ✅ No extra sheet needed for common case
- ❌ Limited to 3 goals (sheet gets too long)
- ❌ No progress visualization

---

### **Option C: Make "Select Goal Team" Actually Navigate**

Currently "Select Goal Team" just dismisses the sheet. Make it actually scroll/highlight the Goal Teams section.

**Implementation:**

1. **Add binding for selected tab**:
```swift
// Pass selected section binding to action sheet
@Binding var selectedSection: Int  // 0 = Goal Teams, 1 = Story
```

2. **Update "Select Goal Team" button**:
```swift
Button(action: {
    activeSheet = nil
    // Switch to Goal Teams tab
    selectedSection = 0
    // Optional: Add scroll animation to goals section
    withAnimation {
        scrollToGoals = true
    }
}) {
    Text("Browse Goal Teams")  // Changed label
        .foregroundColor(Color.repGreen)
        .font(.title2)
        .fontWeight(.bold)
        .padding(.vertical, 5)
}
```

**Benefits:**
- ✅ Minimal code change
- ✅ At least provides context
- ❌ Still requires user to tap goal tile → open detail → tap action → join
- ❌ Doesn't actually simplify the flow

---

**Recommended Approach:**

Implement **Option A (Goal Picker Sheet)** for the best user experience:
- Reduces joining from 8+ clicks to 2-3 clicks
- Shows all goals with context (progress, description)
- Allows instant join OR viewing details
- Follows iOS patterns (drill-down with back button)

**Impact:** Critical - Core user action (joining goal teams) is currently too difficult
**Effort:** Medium-High (new sheet component, join API call)
**Alignment:** Dramatically accelerates Goal Team formation and real-world collaboration

---

## 🟡 MEDIUM PRIORITY (Important but Not Blocking)

### 6. Add Quick Access to "My Purposes" & "My Goals"

**Current Issue:**
No easy way to see "purposes I'm supporting" or "goals I'm on teams for" without scrolling through everything.

**File Location:**
`my-ios-app/Swift FrontEnd/Rep/MainScreen.swift`

**Recommended Solution A - Profile Menu:**

Modify profile picture tap (line 1847-1860):
```swift
ToolbarItem(placement: .topBarLeading) {
    Menu {
        NavigationLink(destination: ProfileView(userId: userId)) {
            Label("My Profile", systemImage: "person.circle")
        }

        NavigationLink(destination: MyPurposesView(userId: userId)) {
            Label("My Purposes", systemImage: "target")
        }

        NavigationLink(destination: MyGoalTeamsView(userId: userId)) {
            Label("My Goal Teams", systemImage: "person.3")
        }

        Divider()

        Button(action: { /* Settings */ }) {
            Label("Settings", systemImage: "gear")
        }
    } label: {
        if let url = currentUser?.profilePictureURL {
            KFImage(url)
                .resizable()
                .scaledToFill()
                .frame(width: 32, height: 32)
                .clipShape(Circle())
        } else {
            Image(systemName: "person.crop.circle")
                .resizable()
                .frame(width: 32, height: 32)
        }
    }
}
```

**New Views Needed:**
1. `my-ios-app/Swift FrontEnd/Rep/MyPurposesView.swift`
2. `my-ios-app/Swift FrontEnd/Rep/MyGoalTeamsView.swift`

**Recommended Solution B - "You" Tab:**

Add fourth segment to segmented picker (line 1829):
```swift
segments: ["Chats", "Network", "Purpose", "You"]
```

Section 3 would show:
- Your active purposes (where you're a lead or member)
- Your active goal teams
- Your recent activity

**Impact:** Medium - Helps users track commitments
**Effort:** High (requires new views and API endpoints)
**Alignment:** Reinforces accountability - "What am I committed to?"

---

### 7. Clarify "Safe" Filter with Better Labeling

**Current Issue:**
"Show: All | Safe" is unclear. What does "Safe" mean?

**File Location:**
`my-ios-app/Swift FrontEnd/Rep/MainScreen.swift`

**Current Implementation:**
- Lines 1713, 1735: "All" and "Safe" labels

**Recommended Changes:**

Option A (Descriptive):
```swift
Text("All Content")  // Instead of "All"
Text("Family-Friendly")  // Instead of "Safe"
```

Option B (With Icons):
```swift
HStack {
    Image(systemName: "globe")
    Text("All")
}

HStack {
    Image(systemName: "checkmark.shield")
    Text("Verified")
}
```

Option C (With Info Icon):
```swift
HStack {
    Text("Safe")
    Button(action: { showSafeFilterInfo = true }) {
        Image(systemName: "info.circle")
            .foregroundColor(.secondary)
            .font(.caption)
    }
}

// Add alert
.alert("Family-Friendly Filter", isPresented: $showSafeFilterInfo) {
    Button("OK", role: .cancel) {}
} message: {
    Text("Shows only verified content suitable for all ages")
}
```

**Impact:** Medium - Improves transparency
**Effort:** Low
**Alignment:** Transparency builds trust in the network

---

### 8. Add Pull-to-Refresh on All Lists

**File Location:**
`my-ios-app/Swift FrontEnd/Rep/MainScreen.swift`

**Current Implementation:**
- Lines 1907-1921: PortalList
- Lines 1932-1975: ChatList (People)

**Recommended Addition:**

Add to PortalList (after line 1907):
```swift
struct PortalList: View {
    var portals: [Portal]
    @AppStorage("userId") var userId: Int = 0
    @ObservedObject var portalsVM: PortalsViewModel  // Pass in from parent
    var section: Int  // Pass in from parent
    var safeOnly: Bool  // Pass in from parent

    var body: some View {
        List {
            ForEach(portals) { portal in
                VStack {
                    NavigationLink {
                        PortalPage(portalId: portal.id, userId: userId)
                    } label: {
                        PortalItem(portal: portal)
                    }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
            }
        }
        .listStyle(.plain)
        .refreshable {  // ADD THIS
            portalsVM.fetchPortals(userId: userId, section: section, safeOnly: safeOnly)
        }
    }
}
```

Add to ChatList (after line 1932):
```swift
.refreshable {
    peopleVM.fetchPeople(userId: userId, section: section)
}
```

Add to ActiveChatList:
```swift
.refreshable {
    peopleVM.fetchPeople(userId: userId, section: 0, force: true)
}
```

**Impact:** Medium - Standard mobile pattern for refreshing
**Effort:** Low
**Alignment:** Keeps users informed with latest data

---

### 9. Improve Goal Team Invite Visibility

**Current Issue:**
Goal team invites appear in Chats tab but might get lost in the chat list.

**File Location:**
`my-ios-app/Swift FrontEnd/Rep/MainScreen.swift`

**Current Implementation:**
- Invites shown via `invitesManager` in chat list
- Green notification dot on "Chats" tab (line 1831)

**Recommended Enhancement:**

Find ActiveChatList component and add banner at top:

```swift
VStack(spacing: 0) {
    // Add banner if invites exist
    if invitesManager.pendingInvites.count > 0 {
        HStack {
            Image(systemName: "person.3.fill")
                .foregroundColor(.white)
            Text("You have \(invitesManager.pendingInvites.count) pending Goal Team invite\(invitesManager.pendingInvites.count == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundColor(.white)
            Spacer()
            Image(systemName: "chevron.down")
                .foregroundColor(.white)
                .font(.caption)
        }
        .padding()
        .background(Color.repGreen)
        .onTapGesture {
            withAnimation {
                expandInvitesSection.toggle()
            }
        }
    }

    // Existing chat list
    List {
        // ... existing code
    }
}
```

**Impact:** Medium - Ensures invites don't get buried
**Effort:** Medium
**Alignment:** Accelerates team formation

---

## 🟢 LOWER PRIORITY (Nice-to-Have Polish)

### 10. Add Haptic Feedback for Key Actions

**File Location:**
`my-ios-app/Swift FrontEnd/Rep/MainScreen.swift`

**Recommended Implementation:**

Create helper extension:
```swift
// Create new file: my-ios-app/Swift FrontEnd/Rep/Utils/HapticFeedback.swift

import UIKit

enum HapticFeedback {
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
```

**Add to key actions:**

Tab switches (line 1832-1842):
```swift
onSelect: { idx in
    HapticFeedback.selection()  // ADD THIS
    section = idx
    // ... existing code
}
```

Toggle People/Portals (line 1628):
```swift
action: {
    HapticFeedback.light()  // ADD THIS
    page = page == .people ? .portals : .people
    // ... existing code
}
```

**Impact:** Low - Polish and modern feel
**Effort:** Low
**Alignment:** Makes app feel responsive

---

### 11. Improve Search with Recent Searches & Suggestions

**File Location:**
`my-ios-app/Swift FrontEnd/Rep/MainScreen.swift`

**Current Implementation:**
- Lines 1653-1683: Search bar with debounced search

**Recommended Enhancement:**

Add storage for recent searches:
```swift
@AppStorage("recentSearches") private var recentSearchesData: Data = Data()

private var recentSearches: [String] {
    get {
        (try? JSONDecoder().decode([String].self, from: recentSearchesData)) ?? []
    }
    set {
        recentSearchesData = (try? JSONEncoder().encode(Array(newValue.prefix(5)))) ?? Data()
    }
}
```

Show recent searches when focused:
```swift
if showSearch {
    VStack {
        // Search field
        HStack {
            TextField("Search...", text: $searchText)
                // ... existing code
        }

        // Recent searches (when empty)
        if searchText.isEmpty && !recentSearches.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                Text("Recent")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 8)

                ForEach(recentSearches, id: \.self) { search in
                    Button(action: {
                        searchText = search
                        performSearch(search)
                    }) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.secondary)
                            Text(search)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                }

                Button(action: { recentSearches = [] }) {
                    Text("Clear Recent")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                }
            }
            .background(Color(.systemBackground))
        }
    }
}
```

Save searches on submit:
```swift
private func saveSearch(_ query: String) {
    guard !query.isEmpty else { return }
    var searches = recentSearches
    searches.removeAll { $0 == query }
    searches.insert(query, at: 0)
    recentSearches = Array(searches.prefix(5))
}
```

**Impact:** Low - Convenience for power users
**Effort:** Medium
**Alignment:** Faster access to known people/purposes

---

### 12. Add Swipe Actions on Lists

**File Location:**
`my-ios-app/Swift FrontEnd/Rep/MainScreen.swift`

**Recommended Implementation:**

Portal list swipe actions (line 1908-1918):
```swift
ForEach(portals) { portal in
    NavigationLink {
        PortalPage(portalId: portal.id, userId: userId)
    } label: {
        PortalItem(portal: portal)
    }
    .swipeActions(edge: .trailing) {
        Button {
            sharePortal(portal)
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        .tint(.blue)

        Button {
            bookmarkPortal(portal)
        } label: {
            Label("Bookmark", systemImage: "bookmark")
        }
        .tint(.orange)
    }
}
```

People list swipe actions:
```swift
.swipeActions(edge: .trailing) {
    Button {
        messageUser(user)
    } label: {
        Label("Message", systemImage: "message")
    }
    .tint(.green)
}
```

**Impact:** Low - Power user efficiency
**Effort:** Medium
**Alignment:** Quick access to common actions

---

### 13. Enhance Portal/Goal Cards with Visual Hierarchy

**File Location:**
`my-ios-app/Swift FrontEnd/Rep/PortalItem.swift`

**Current Implementation:**
- Lines 18-81: PortalItem card layout

**Recommended Changes:**

```swift
var body: some View {
    HStack(alignment: .top, spacing: 16) {
        // Image (keep same)
        if let urlString = portal.mainImageUrl, let url = URL(string: urlString) {
            KFImage(url)
                .resizable()
                .aspectRatio(16/9, contentMode: .fill)
                .frame(width: imageWidth, height: imageHeight)
                .clipped()
                .cornerRadius(3)
        } else {
            Color.gray.opacity(0.2)
                .frame(width: imageWidth, height: imageHeight)
                .cornerRadius(3)
        }

        VStack(alignment: .leading, spacing: 4) {
            // ENHANCED: Make name more prominent
            Text(portal.name)
                .font(.system(size: 19, weight: .bold))  // Increased from 17
                .foregroundColor(.primary)
                .lineLimit(2)
                .truncationMode(.tail)

            // ENHANCED: Add progress indicator if available
            if let progressPercent = portal.progressPercent {
                HStack(spacing: 4) {
                    ProgressView(value: progressPercent, total: 100)
                        .tint(Color.repGreen)
                        .frame(height: 4)
                    Text("\(Int(progressPercent))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // REDUCED: Make category less prominent
            if let category = portal.categories_id {
                Text("Category \(category)")
                    .font(.system(size: 11))  // Reduced from 12
                    .foregroundColor(.secondary.opacity(0.7))  // More faded
            }

            if let subtitle = portal.subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 15))  // Reduced from 17
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            HStack {
                if let city = portal.cities_id {
                    Text("City \(city)")
                        .font(.system(size: 11))  // Reduced from 12
                        .foregroundColor(.secondary.opacity(0.7))
                }
                Spacer()
                // ENHANCED: Make lead count more prominent with icon
                if let count = portal._c_users_count {
                    HStack(spacing: 2) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 10))
                        Text("\(count)")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(Color.repGreen)
                }
            }
        }
    }
    // ... rest of styling
}
```

**Impact:** Low - Improves scanability
**Effort:** Low
**Alignment:** Emphasizes Value Metrics and progress

---

### 14. Onboarding: Add Contextual Tooltips on First Use

**File Location:**
`my-ios-app/Swift FrontEnd/Rep/RepProfile/OnboardingView.swift`

**Current Implementation:**
- Lines 97-185: AppWalkthroughView with 5 screens

**Recommended Addition:**

After walkthrough completes, show one-time contextual tooltips:

Create new file: `my-ios-app/Swift FrontEnd/Rep/Components/ContextualTooltipManager.swift`

```swift
import SwiftUI

class ContextualTooltipManager: ObservableObject {
    @AppStorage("hasSeenToggleTooltip") var hasSeenToggleTooltip = false
    @AppStorage("hasSeenSearchTooltip") var hasSeenSearchTooltip = false
    @AppStorage("hasSeenAddTooltip") var hasSeenAddTooltip = false

    func shouldShow(_ tooltip: TooltipType) -> Bool {
        switch tooltip {
        case .toggle: return !hasSeenToggleTooltip
        case .search: return !hasSeenSearchTooltip
        case .add: return !hasSeenAddTooltip
        }
    }

    func markSeen(_ tooltip: TooltipType) {
        switch tooltip {
        case .toggle: hasSeenToggleTooltip = true
        case .search: hasSeenSearchTooltip = true
        case .add: hasSeenAddTooltip = true
        }
    }

    enum TooltipType {
        case toggle, search, add
    }
}

struct ContextualTooltip: View {
    let message: String
    let arrow: ArrowDirection
    @Binding var isShowing: Bool

    enum ArrowDirection {
        case up, down, left, right
    }

    var body: some View {
        if isShowing {
            VStack(spacing: 4) {
                if arrow == .down {
                    arrowView
                }

                Text(message)
                    .font(.caption)
                    .padding(8)
                    .background(Color.black.opacity(0.85))
                    .foregroundColor(.white)
                    .cornerRadius(8)

                if arrow == .up {
                    arrowView
                }
            }
            .transition(.opacity.combined(with: .scale))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    withAnimation {
                        isShowing = false
                    }
                }
            }
        }
    }

    private var arrowView: some View {
        Image(systemName: arrow == .down ? "arrowtriangle.down.fill" : "arrowtriangle.up.fill")
            .foregroundColor(.black.opacity(0.85))
            .font(.caption)
    }
}
```

**Add to MainScreen.swift:**

```swift
@StateObject private var tooltipManager = ContextualTooltipManager()
@State private var showToggleTooltip = false

.onAppear {
    if tooltipManager.shouldShow(.toggle) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation {
                showToggleTooltip = true
            }
        }
    }
}

// Add overlay near toggle button
.overlay(alignment: .bottom) {
    if showToggleTooltip {
        ContextualTooltip(
            message: "👆 Tap here to toggle between People and Portals",
            arrow: .down,
            isShowing: $showToggleTooltip
        )
        .padding(.bottom, 70)
        .onDisappear {
            tooltipManager.markSeen(.toggle)
        }
    }
}
```

**Impact:** Low - Helps new users discover features
**Effort:** Medium
**Alignment:** Bridges gap between walkthrough and actual use

---

### 15. Add "What's Next?" Prompts for Engagement

**File Location:**
Create new component file

**Recommended Implementation:**

Create new file: `my-ios-app/Swift FrontEnd/Rep/Components/SuccessPromptView.swift`

```swift
import SwiftUI

struct SuccessPromptView: View {
    let title: String
    let emoji: String
    let nextSteps: [NextStep]
    let onDismiss: () -> Void

    struct NextStep {
        let title: String
        let icon: String
        let action: () -> Void
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(emoji)
                .font(.system(size: 60))

            Text(title)
                .font(.title2)
                .fontWeight(.bold)

            Text("What's next:")
                .font(.headline)
                .padding(.top)

            VStack(spacing: 12) {
                ForEach(nextSteps.indices, id: \.self) { index in
                    Button(action: {
                        nextSteps[index].action()
                        onDismiss()
                    }) {
                        HStack {
                            Image(systemName: nextSteps[index].icon)
                                .frame(width: 24)
                                .foregroundColor(Color.repGreen)
                            Text(nextSteps[index].title)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
            }

            Button(action: onDismiss) {
                Text("Got it!")
                    .fontWeight(.semibold)
                    .foregroundColor(Color.repGreen)
                    .padding(.top, 8)
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 20)
    }
}
```

**Usage Example:**

After joining a goal team:
```swift
.sheet(isPresented: $showSuccessPrompt) {
    SuccessPromptView(
        title: "You're now on this team!",
        emoji: "🎉",
        nextSteps: [
            SuccessPromptView.NextStep(
                title: "Message the team",
                icon: "message.fill",
                action: { openTeamChat() }
            ),
            SuccessPromptView.NextStep(
                title: "View the goal dashboard",
                icon: "chart.bar.fill",
                action: { openGoalDashboard() }
            ),
            SuccessPromptView.NextStep(
                title: "Invite others to join",
                icon: "person.badge.plus",
                action: { openInvite() }
            )
        ],
        onDismiss: { showSuccessPrompt = false }
    )
    .presentationDetents([.medium])
}
```

**Impact:** Low - Guides users to meaningful next actions
**Effort:** Medium
**Alignment:** Drives real-world action and team coordination

---

## 📊 IMPLEMENTATION PRIORITY MATRIX

| Priority | Recommendation | Files to Modify | Effort | Impact | Implement First |
|----------|---------------|-----------------|--------|--------|-----------------|
| 🔴 HIGH  | #1 People/Portal Toggle | MainScreen.swift | Medium | Critical | ✅ YES |
| 🔴 HIGH  | #2 Tab Label Clarity | MainScreen.swift | Low | High | ✅ YES |
| 🔴 HIGH  | #3 Action Sheet Redesign | MainScreen.swift | Medium | High | ✅ YES |
| 🔴 HIGH  | #4 Better Empty States | MainScreen.swift + new EmptyStateView.swift | Medium | High | ✅ YES |
| 🔴 HIGH  | #5 Simplify Goal Joining | PortalPage.swift + GoalsDetailView.swift | Medium-High | Critical | ✅ YES |
| 🟡 MED   | #6 My Purposes/Goals | MainScreen.swift + new views | High | Medium | Later |
| 🟡 MED   | #7 Clarify Safe Filter | MainScreen.swift | Low | Medium | Quick win ✅ |
| 🟡 MED   | #8 Pull-to-Refresh | MainScreen.swift | Low | Medium | Quick win ✅ |
| 🟡 MED   | #9 Goal Invite Visibility | MainScreen.swift | Medium | Medium | Later |
| 🟢 LOW   | #10 Haptic Feedback | New HapticFeedback.swift + MainScreen.swift | Low | Low | Polish pass |
| 🟢 LOW   | #11 Search Enhancements | MainScreen.swift | Medium | Low | Polish pass |
| 🟢 LOW   | #12 Swipe Actions | MainScreen.swift + PortalItem.swift | Medium | Low | Polish pass |
| 🟢 LOW   | #13 Visual Hierarchy | PortalItem.swift | Low | Low | Polish pass |
| 🟢 LOW   | #14 Contextual Tooltips | New ContextualTooltipManager.swift + MainScreen.swift | Medium | Low | After launch |
| 🟢 LOW   | #15 Success Prompts | New SuccessPromptView.swift | Medium | Low | After launch |

---

## 🎯 QUICK WIN RECOMMENDATIONS

Start with these for immediate impact with minimal effort:

1. **#2 Tab Label Clarity** (5 minutes)
   - Change `["Chats", "Network", "Purpose"]` to `["Chats", "My Network", "Purposes"]`

2. **#7 Clarify Safe Filter** (10 minutes)
   - Change "All" → "All Content"
   - Change "Safe" → "Family-Friendly"

3. **#8 Pull-to-Refresh** (15 minutes)
   - Add `.refreshable { }` to all list views

---

## 🚀 SUGGESTED IMPLEMENTATION ORDER

### Phase 1: Critical UX (Week 1)
- ✅ #2 Tab Label Clarity
- ✅ #7 Clarify Safe Filter
- ✅ #8 Pull-to-Refresh
- ⏳ #1 People/Portal Toggle
- ⏳ #3 Action Sheet Redesign
- ⏳ #5 Simplify Goal Joining Flow (PRIORITY - most impactful)

### Phase 2: User Guidance (Week 2-3)
- ⏳ #4 Better Empty States
- ⏳ #9 Goal Invite Visibility

### Phase 3: Advanced Features (Week 4+)
- ⏳ #6 My Purposes/Goals Quick Access
- ⏳ #11 Search Enhancements
- ⏳ #12 Swipe Actions

### Phase 4: Polish (Post-Launch)
- ⏳ #10 Haptic Feedback
- ⏳ #13 Visual Hierarchy
- ⏳ #14 Contextual Tooltips
- ⏳ #15 Success Prompts

---

## 📝 NOTES ON PRODUCT VISION ALIGNMENT

All recommendations maintain the core "People-Purpose-Value Rolodex" structure:

✅ **Preserved:**
- Three-tab navigation (Chats/Network/Purpose)
- People vs Portals toggle concept
- Goal Teams as primary collaboration unit
- Purpose-driven focus

✅ **Enhanced:**
- Made existing features more discoverable
- Guided users toward real-world action
- Reduced friction in team formation
- Emphasized progress and value metrics

✅ **Aligned with Goals:**
- Minimize screen time (prompts guide to action, then off app)
- Drive real results (success prompts → next actions)
- In-person collaboration (team chat → meeting coordination)

---

**Document Created:** December 24, 2025
**Last Updated:** December 24, 2025
**Status:** Ready for implementation
