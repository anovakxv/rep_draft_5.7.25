# Navigation Crash Analysis - MainScreen, PortalPage, GoalsDetailView

**Date**: December 10, 2025
**Status**: Critical issues identified - Conservative fixes recommended

## Executive Summary

Analysis of the three main navigation pages reveals **3 critical crash causes** related to network request lifecycle management. All issues can be fixed with minimal, conservative changes that add safety without altering app behavior.

## Critical Issues Found

### Issue #1: No Request Cancellation in PortalViewModel ⚠️ HIGH RISK

**Location**: `my-ios-app/Swift FrontEnd/Rep/PortalPage.swift` lines 33-101

**Problem**:
PortalViewModel has **NO cleanup** when the view is dismissed. If a user navigates to PortalPage and then quickly navigates away, network requests continue running and try to update `@Published` properties on a dismissed view, causing crashes.

**Evidence**:
```swift
class PortalViewModel: ObservableObject {
    // NO deinit
    // NO task tracking
    // NO cancellation mechanism

    func fetchPortalDetail(...) {
        URLSession.shared.dataTask(with: request) { data, _, error in
            // Completion handler runs even after view dismissed
            DispatchQueue.main.async {
                self.portalDetail = response.result  // ❌ CRASH if view dismissed
            }
        }.resume()
    }
}
```

**Crash Scenario**:
1. User taps Portal from MainScreen
2. PortalViewModel starts 3 network requests (detail, goals, increments)
3. User immediately taps back button
4. View dismissed, ViewModel deallocated
5. Network responses arrive
6. Completion handlers try to update deallocated object → **CRASH**

**Fix Complexity**: Low (add 15 lines of code)

---

### Issue #2: No Request Cancellation in GoalsDetailViewModel ⚠️ HIGH RISK

**Location**: `my-ios-app/Swift FrontEnd/Rep/GoalsDetailView.swift` lines 574-713

**Problem**:
Identical issue to PortalViewModel. The `load()` function makes network calls with no cancellation mechanism.

**Evidence**:
```swift
class GoalsDetailViewModel: ObservableObject {
    // NO deinit
    // NO task tracking

    func load(goalId: Int) {
        URLSession.shared.dataTask(with: request) { data, _, _ in
            // Complex response parsing (lines 612-708)
            DispatchQueue.main.async {
                self.goal = Goal(...)  // ❌ CRASH if view dismissed
                self.team = apiGoal.team?.map { ... }  // ❌ CRASH
                self.feed = limitedLogs.compactMap { ... }  // ❌ CRASH
            }
        }.resume()
    }
}
```

**Additional Evidence of Prior Crashes**:
Lines 51-52, 261-263 show a "Crash Prevention Guard":
```swift
// --- Crash Prevention Guard ---
@State private var hasAppeared = false

.onAppear {
    hasAppeared = true
}
.disabled(!hasAppeared)  // Disables entire view until onAppear completes
```

This band-aid fix proves they've already experienced crashes and tried to work around them instead of fixing the root cause.

**Fix Complexity**: Low (add 15 lines of code)

---

### Issue #3: Multiple Concurrent Network Calls on Navigation ⚠️ MEDIUM RISK

**Problem**:
When navigating between pages, multiple network requests fire simultaneously without coordination. If user rapidly navigates (MainScreen → Portal → GoalDetail → Back → Portal), requests from previous navigations are still running.

**Evidence**:
- **PortalPage.onAppear** (estimated lines 200-250): Fires 3 requests immediately
- **GoalsDetailView.onAppear** (lines 258-260): Fires 2+ requests immediately
- **MainScreen** already has throttling, but other pages don't

**Crash Scenario**:
1. User rapidly taps: Portal A → Back → Portal B → Back → Portal A
2. 9+ network requests queued (3 per portal visit)
3. All responses try to update UI simultaneously
4. Memory pressure + race conditions → **CRASH**

**Fix Complexity**: Low (already fixed in MainScreen, apply same pattern)

---

## Recommended Conservative Fixes

### Fix #1: Add Request Cancellation to PortalViewModel

**File**: `PortalPage.swift`

**Changes**:
```swift
class PortalViewModel: ObservableObject {
    @Published var portalDetail: PortalDetail?
    @Published var portalGoals: [Goal] = []
    @Published var section = 0
    @Published var isEditPresented = false
    @Published var reportingIncrements: [ReportingIncrement] = []

    @AppStorage("jwtToken") var jwtToken: String = ""

    // ADD: Task tracking
    private var detailTask: URLSessionDataTask?
    private var goalsTask: URLSessionDataTask?
    private var incrementsTask: URLSessionDataTask?

    // ADD: Cleanup
    deinit {
        cancelAllRequests()
    }

    func cancelAllRequests() {
        detailTask?.cancel()
        goalsTask?.cancel()
        incrementsTask?.cancel()
    }

    func fetchPortalDetail(portalId: Int, userId: Int) {
        // ADD: Cancel previous request
        detailTask?.cancel()

        let urlString = "\(APIConfig.baseURL)/api/portal/details?portals_id=\(portalId)&user_id=\(userId)"
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }

        // CHANGE: Store task
        detailTask = URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data else { return }
            do {
                let response = try JSONDecoder().decode(PortalDetailResponse.self, from: data)
                DispatchQueue.main.async {
                    self.portalDetail = response.result
                }
            } catch {
                print("Decode error:", error)
            }
        }
        // CHANGE: Resume stored task
        detailTask?.resume()
    }

    // REPEAT for fetchPortalGoals() and fetchReportingIncrements()
}
```

**Risk Level**: MINIMAL
- Only adds safety, doesn't change behavior
- Same pattern already proven safe in MainScreen
- No user-facing changes

**Testing**: Navigate to portal, immediately tap back. Should not crash.

---

### Fix #2: Add Request Cancellation to GoalsDetailViewModel

**File**: `GoalsDetailView.swift`

**Changes**: Same pattern as Fix #1
```swift
class GoalsDetailViewModel: ObservableObject {
    // ... existing properties ...

    // ADD: Task tracking
    private var loadTask: URLSessionDataTask?

    // ADD: Cleanup
    deinit {
        loadTask?.cancel()
    }

    func load(goalId: Int) {
        // ADD: Cancel previous request
        loadTask?.cancel()

        // ... existing URL setup ...

        // CHANGE: Store task
        loadTask = URLSession.shared.dataTask(with: request) { data, _, _ in
            // ... existing response handling ...
        }
        // CHANGE: Resume stored task
        loadTask?.resume()
    }
}
```

**Risk Level**: MINIMAL

**Additional Benefit**: Can remove the "Crash Prevention Guard" band-aid fix once this is implemented and tested.

---

### Fix #3: Remove "Crash Prevention Guard" Band-Aid (AFTER Fix #2 is validated)

**File**: `GoalsDetailView.swift` lines 51-52, 261-263

**Current Band-Aid**:
```swift
@State private var hasAppeared = false

.onAppear {
    hasAppeared = true
}
.disabled(!hasAppeared)  // Disables entire view
```

**After Fix #2 is proven stable, remove**:
```swift
// Remove: @State private var hasAppeared = false
// Remove: hasAppeared = true
// Remove: .disabled(!hasAppeared)
```

**Risk Level**: LOW (but ONLY after Fix #2 is validated in production for 1-2 weeks)

---

## Implementation Plan (Conservative Approach)

### Phase 1: Add Safety to PortalViewModel (Week 1)
1. Implement Fix #1 (request cancellation)
2. Test locally with rapid navigation
3. Deploy to TestFlight
4. Monitor crash reports for 3-5 days

### Phase 2: Add Safety to GoalsDetailViewModel (Week 2)
1. IF Phase 1 shows no issues, implement Fix #2
2. Test locally with rapid navigation
3. Deploy to TestFlight
4. Monitor crash reports for 3-5 days

### Phase 3: Remove Band-Aid (Week 3) - OPTIONAL
1. IF Phases 1-2 show crash rate reduced >80%, remove band-aid
2. Test locally
3. Deploy to TestFlight
4. Monitor closely

### Phase 4: If crashes persist, investigate deeper
- Add more detailed crash logging
- Consider adding Crashlytics/Sentry
- Analyze specific crash patterns

---

## Why These Fixes Are Safe

1. **Proven Pattern**: Same approach already working in MainScreen's PortalsViewModel and PeopleViewModel
2. **Additive Only**: We're only adding safety mechanisms, not changing existing logic
3. **Graceful Degradation**: If cancellation fails, app behavior unchanged
4. **No User-Facing Changes**: Navigation and UI remain identical

---

## Alternative: Do Nothing

**If you choose not to fix**:
- Crashes will continue when users navigate quickly
- User frustration will increase
- App Store reviews may mention crashes
- But no NEW problems will be introduced

**Recommendation**: Implement Fix #1 and Fix #2. They are low-risk, high-reward changes that follow patterns already proven in your codebase.

---

## Other Potential Issues (Lower Priority)

### Minor Issue: No Memory Warning Handlers
Neither PortalViewModel nor GoalsDetailViewModel respond to memory warnings. This is less critical than request cancellation but could be added later:

```swift
init() {
    NotificationCenter.default.addObserver(
        forName: UIApplication.didReceiveMemoryWarningNotification,
        object: nil,
        queue: .main
    ) { [weak self] _ in
        // Clear cached data if needed
    }
}
```

**Priority**: LOW (add only if crashes persist after Fixes #1-2)

---

## Success Metrics

**Before Fixes**:
- Baseline crash rate: [Measure current rate]
- Navigation speed: Already fast (instant cache)

**After Fixes**:
- Target: >80% reduction in navigation crashes
- Navigation speed: Unchanged (fixes don't add delays)
- User experience: Improved stability, no perceivable difference

---

## Conclusion

The crashes are almost certainly caused by **network request completion handlers updating deallocated ViewModels**. The fixes are conservative, proven safe in other parts of your codebase, and require minimal code changes.

**Recommendation**: Implement Fix #1 first, validate for a few days, then implement Fix #2. Total implementation time: ~30 minutes per fix.
