# MainScreen.swift Refactoring Plan

**Status**: Deferred - Performance fixes prioritized first
**Date**: December 10, 2025
**Current File Size**: 1971 lines

## Executive Summary

The MainScreen.swift file handles the primary navigation and data management for the iOS app. While the code is functional, it exhibits architectural issues that impact maintainability. However, **a complete refactor should be deferred** until critical performance issues (freezes/crashes on rapid tab switches) are resolved through targeted fixes.

## Current Issues

### Performance Problems (Critical - Address First)
- App freezes when users click multiple pages in rapid succession
- Race conditions on rapid tab switches (lines 273-324)
- Main thread blocking with 25+ `DispatchQueue.main.async` calls
- No request cancellation when users switch tabs
- Background loading interferes with foreground user actions (lines 839-846)
- 39 network calls throughout the file with potential for concurrent conflicts

### Architectural Issues (Non-Critical - Address Later)
- 1971 lines in a single file
- 53 state properties distributed across multiple structs
- Complex state interdependencies
- Difficult to test in isolation
- Hard to onboard new developers

## Why NOT to Refactor Immediately

1. **Risk/Reward Imbalance**: Full refactor is massive undertaking with high risk of introducing new bugs in production
2. **Root Cause Mismatch**: Freezing/crashing is a **performance issue**, not an architectural issue
3. **User Impact**: Users care about stability, not code cleanliness
4. **Refactor Benefits Don't Address User Pain**:
   - ✅ Developer productivity (internal benefit)
   - ✅ Long-term maintainability (internal benefit)
   - ❌ User-facing performance (may not improve)
   - ❌ Immediate stability (could worsen if done incorrectly)

## Recommended Phased Approach

### Phase 1: Critical Performance Fixes (1-2 weeks) - **DO THIS FIRST**

#### 1.1 Add Request Cancellation
```swift
class PortalsViewModel: ObservableObject {
    private var currentTask: URLSessionDataTask?

    func fetchPortals(...) {
        currentTask?.cancel() // Cancel previous request
        currentTask = URLSession.shared.dataTask(...)
        currentTask?.resume()
    }

    deinit {
        currentTask?.cancel()
    }
}

class PeopleViewModel: ObservableObject {
    private var activeFetchTask: URLSessionDataTask?
    private var searchTask: URLSessionDataTask?

    func fetchPeople(...) {
        activeFetchTask?.cancel()
        activeFetchTask = URLSession.shared.dataTask(...)
        activeFetchTask?.resume()
    }

    deinit {
        activeFetchTask?.cancel()
        searchTask?.cancel()
    }
}
```

#### 1.2 Improve Throttling Mechanism
Current Task-based approach (lines 292-303) is good but needs refinement:
```swift
class PeopleViewModel: ObservableObject {
    private var activeRefreshTask: Task<Void, Never>?
    private var lastRefreshRequestTime: Date = .distantPast
    private let minimumRefreshInterval: TimeInterval = 0.25

    func fetchPeople(...) {
        // Cancel previous task
        activeRefreshTask?.cancel()

        let now = Date()
        let timeSinceLastRequest = now.timeIntervalSince(lastRefreshRequestTime)

        if timeSinceLastRequest < minimumRefreshInterval && !force {
            return // Too soon
        }

        lastRefreshRequestTime = now

        // Create cancellable task
        activeRefreshTask = Task {
            guard !Task.isCancelled else { return }
            await performFetch()
        }
    }
}
```

#### 1.3 Debounce Tab Switches
```swift
struct MainScreen: View {
    @State private var tabSwitchDebouncer: Timer?

    var body: some View {
        // ...
        .onChange(of: section) { newSection in
            tabSwitchDebouncer?.invalidate()
            tabSwitchDebouncer = Timer.scheduledTimer(
                withTimeInterval: 0.2,
                repeats: false
            ) { _ in
                handleTabSwitch(to: newSection)
            }
        }
    }

    private func handleTabSwitch(to newSection: Int) {
        // Cancel any in-flight requests
        peopleVM.cancelPendingRefreshes(section: newSection)
        portalsVM.cancelPendingRequests()

        // Fetch new data
        if page == .portals {
            portalsVM.fetchPortals(userId: userId, section: newSection, isTabSwitch: true)
        } else {
            peopleVM.fetchPeople(userId: userId, section: newSection, isTabSwitch: true)
        }
    }
}
```

#### 1.4 Move Background Loading to Lower Priority
```swift
class PortalsViewModel: ObservableObject {
    func loadBackgroundData(from: Int, to: Int, userId: Int, safeOnly: Bool) {
        // Use utility queue instead of default priority
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.performBackgroundFetch(targetSection: to, userId: userId, safeOnly: safeOnly)
        }
    }
}
```

#### 1.5 Add Memory Pressure Handling
```swift
class PortalsViewModel: ObservableObject {
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    @objc private func handleMemoryWarning() {
        // Clear cached background data
        backgroundPortalsTab0 = []
        backgroundPortalsTab1 = []
        backgroundPortalsTab2 = []
    }
}
```

### Phase 2: Measure & Validate (1 week)

1. **Add Performance Monitoring**
   - Use Instruments to profile Time Profiler
   - Monitor main thread usage
   - Track network request overlaps

2. **Add Crash Analytics**
   - Integrate crash reporting (Crashlytics/Sentry)
   - Track specific crash patterns
   - Monitor freeze detection

3. **Beta Test with Real Users**
   - TestFlight rollout to subset of users
   - Gather feedback on stability improvements
   - Monitor crash rates before/after

4. **Validate Fixes**
   - Confirm freezes/crashes reduced by >80%
   - Ensure tab switching is smooth
   - Check memory usage is stable

### Phase 3: Architectural Refactor (Future - Only if Needed)

**Decision Point**: Only proceed if Phase 1-2 don't adequately solve performance issues OR if maintainability becomes a blocking issue for feature development.

If proceeding, break into small chunks with testing between each:

#### Week 1: Extract Models
```
MainScreen/
├── Models/
│   ├── ActiveChat.swift
│   ├── ChatModel.swift
│   ├── MessageModel.swift
│   └── APIResponses.swift
```

**Testing**: Ensure all existing functionality works unchanged.

#### Week 2: Extract Networking Layer
```
MainScreen/
├── Networking/
│   ├── APIService.swift
│   ├── APIEndpoint.swift
│   └── NetworkError.swift
```

Example:
```swift
protocol APIService {
    func fetch<T: Decodable>(
        endpoint: APIEndpoint,
        completion: @escaping (Result<T, Error>) -> Void
    ) -> URLSessionDataTask?
}

enum APIEndpoint {
    case activeChats(userId: Int)
    case people(userId: Int, section: Int)
    case portals(userId: Int, section: Int, safeOnly: Bool)

    var path: String {
        switch self {
        case .activeChats(let userId):
            return "/api/active_chat_list?user_id=\(userId)"
        case .people(let userId, let section):
            let tab = section == 1 ? "ntwk" : "all"
            return "/api/filter_people?user_id=\(userId)&tab=\(tab)"
        case .portals(let userId, let section, let safeOnly):
            let tab = section == 0 ? "open" : (section == 1 ? "ntwk" : "all")
            let safeParam = safeOnly ? "&safe_only=true" : ""
            return "/api/portal/filter_network_portals?user_id=\(userId)&tab=\(tab)\(safeParam)"
        }
    }
}
```

**Testing**: Verify all API calls work identically.

#### Week 3: Extract ViewModels
```
MainScreen/
├── ViewModels/
│   ├── MainScreenViewModel.swift  // Coordinator
│   ├── PortalsViewModel.swift     // Already exists, enhance
│   └── PeopleViewModel.swift      // Already exists, enhance
```

Create unified coordinator:
```swift
class MainScreenViewModel: ObservableObject {
    @Published var page: MainScreen.Page = .portals
    @Published var section = 2
    @Published var showSearch = false
    @Published var searchText = ""
    @Published var mainActiveSheet: MainScreenContent.ActiveSheet?
    @Published var pendingAction: MainActionSheetAction?
    @Published var showOnlySafePortals = false
    @Published var openNeedsAttention: Bool = false

    // Delegate to child view models
    let peopleVM = PeopleViewModel()
    let portalsVM = PortalsViewModel()

    // Computed properties for filtered data
    var filteredUsers: [User] {
        // Consolidate filtering logic here
    }

    var filteredActiveChats: [ActiveChat] {
        // Consolidate filtering logic here
    }

    var filteredPortals: [Portal] {
        // Consolidate filtering logic here
    }

    // Lifecycle
    func onAppear() {
        setupSocketNotifications()
        fetchInitialData()
        startBackgroundPolling()
    }

    func onDisappear() {
        cleanupSocketNotifications()
        cancelAllRequests()
    }
}
```

**Testing**: Ensure state management works correctly.

#### Week 4: Extract View Components
```
MainScreen/
├── Views/
│   ├── MainScreen.swift               // Slim coordinator
│   ├── Components/
│   │   ├── MainSegmentedPicker.swift
│   │   ├── ChatsList.swift
│   │   ├── ActiveChatList.swift
│   │   ├── PortalList.swift
│   │   └── ChatList.swift
│   └── Sheets/
│       └── MainActionSheet.swift
```

Break down into focused components:
```swift
struct ChatsList: View {
    @ObservedObject var peopleVM: PeopleViewModel
    @ObservedObject var invitesManager: GoalTeamInvitesManager
    let filteredActiveChats: [ActiveChat]

    var body: some View {
        List {
            if !invitesManager.pendingInvites.isEmpty {
                InviteNotificationView(invites: invitesManager.pendingInvites)
            }

            ForEach(filteredActiveChats) { chat in
                if chat.type == "direct" {
                    DirectChatRow(chat: chat)
                } else {
                    GroupChatRow(chat: chat)
                }
            }
        }
    }
}
```

**Testing**: Visual regression testing, ensure navigation works.

#### Week 5: Testing & Rollout
- Comprehensive integration testing
- Beta test with 10% of users
- Monitor for regressions
- Gradual rollout to 100%

## Alternative: Modern SwiftUI Patterns (iOS 16+)

If targeting iOS 16+, consider these improvements:

### Use NavigationStack
```swift
NavigationStack {
    MainScreenView()
        .navigationDestination(for: ChatDestination.self) { destination in
            switch destination {
            case .directChat(let user):
                Chat(userId: user.id, userName: user.fullName ?? "")
            case .groupChat(let group):
                GroupChatView(viewModel: GroupChatViewModel(...))
            }
        }
}
```

### Use TabView for Main Navigation
```swift
TabView(selection: $viewModel.section) {
    ChatsList(...)
        .tabItem {
            Label("Chats", systemImage: "bubble.left.and.bubble.right")
                .overlay(viewModel.openNeedsAttention ? AttentionDot() : nil)
        }
        .tag(0)

    NetworkView(...)
        .tabItem {
            Label("Network", systemImage: "person.2")
        }
        .tag(1)

    AllView(...)
        .tabItem {
            Label("All", systemImage: "rectangle.grid.2x2")
        }
        .tag(2)
}
```

### Combine-Based Networking
```swift
import Combine

func fetchPeople(userId: Int, section: Int) -> AnyPublisher<[User], Error> {
    let tab = section == 1 ? "ntwk" : "all"
    let urlString = "\(APIConfig.baseURL)/api/filter_people?user_id=\(userId)&tab=\(tab)"

    return URLSession.shared
        .dataTaskPublisher(for: apiRequest(urlString))
        .map(\.data)
        .decode(type: UsersAPIResponse.self, decoder: JSONDecoder())
        .map(\.result)
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
}

// Usage with cancellation:
private var cancellables = Set<AnyCancellable>()

func loadPeople() {
    fetchPeople(userId: userId, section: section)
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    self.errorMessage = error.localizedDescription
                }
            },
            receiveValue: { users in
                self.users = users
            }
        )
        .store(in: &cancellables)
}
```

## Benefits of Future Refactoring

### Developer Benefits
- **Maintainability**: Smaller files easier to understand and modify
- **Testability**: Decoupled components can be unit tested
- **Onboarding**: New developers can understand components in isolation
- **Velocity**: Adding features becomes faster with clear boundaries
- **Reusability**: Components can be used across the app

### Potential User Benefits (Secondary)
- **Indirect performance**: Better code organization can lead to better performance optimizations
- **Fewer bugs**: Clear separation of concerns reduces accidental interactions
- **Faster features**: Development velocity improvements mean faster iteration

### Business Benefits
- **Reduced technical debt**: Easier to maintain long-term
- **Lower development costs**: Less time debugging complex interactions
- **Scalability**: Can add features without exponential complexity growth

## Decision Framework

**When to Proceed with Full Refactor:**
1. ✅ Phase 1 performance fixes have been validated as successful
2. ✅ No new critical bugs or crashes introduced
3. ✅ User satisfaction metrics improved
4. ✅ Development team has bandwidth (2+ weeks dedicated time)
5. ✅ Feature development can be paused for refactor period

**Red Flags - DO NOT Refactor if:**
- ❌ Performance issues persist after Phase 1 fixes
- ❌ Active critical bugs in production
- ❌ Major feature deadlines approaching
- ❌ Team is understaffed or overworked
- ❌ Insufficient test coverage to catch regressions

## Success Metrics

### Phase 1 Success Criteria
- Crash rate reduced by >80%
- Freeze/hang reports reduced by >90%
- Main thread blocking time reduced by >50%
- Tab switch latency <200ms consistently

### Phase 3 Success Criteria (if refactored)
- All existing functionality preserved
- No new crashes introduced
- Test coverage >70% on new components
- File size of largest component <500 lines
- Build time unchanged or improved
- Development velocity increased (measured over 3 months)

## Conclusion

**Recommendation**: Execute Phase 1 performance fixes immediately. Defer architectural refactor until:
1. Performance is stable
2. Team has capacity
3. Business priorities allow

The proposed refactor is architecturally sound but should be treated as a **long-term investment**, not an urgent fix. Stability and user experience must come first.

---

**Document Version**: 1.0
**Last Updated**: December 10, 2025
**Next Review**: After Phase 1 completion (estimate 2-3 weeks)
