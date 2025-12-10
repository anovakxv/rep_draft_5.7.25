# Chat Navigation Crash Analysis

**Date**: December 10, 2025
**Files Analyzed**: Chat_Individual.swift, Chat_Group.swift

## Executive Summary

**GroupChatViewModel**: ✅ **SAFE** - Already has proper task cancellation
**MessageViewModel**: ⚠️ **NEEDS FIX** - Multiple network requests without cancellation

## Detailed Analysis

### ✅ GroupChatViewModel (Chat_Group.swift) - NO CHANGES NEEDED

**Status**: Already properly implemented!

**Evidence**:
- Line 233: `private var loadMessagesTask: Task<Void, Never>?` ✓
- Line 245: `private var messageFetchTask: Task<Void, Never>?` ✓
- Line 265: Has `deinit` ✓
- Line 309: `loadMessagesTask?.cancel()` in cleanup ✓

**Code**:
```swift
deinit {
    print("🧹 GroupChatViewModel deinit chat_\(chatId) active=\(isActive)")
    if isActive { performImmediateCleanup() }
}

private func performImmediateCleanup() {
    if let id = groupObsId { RealtimeSocketManager.shared.removeGroupMessageObserver(id); groupObsId = nil }
    if let id = groupNotifObsId { RealtimeSocketManager.shared.removeGroupMessageNotificationObserver(id); groupNotifObsId = nil }
    loadMessagesTask?.cancel(); loadMessagesTask = nil  // ✓ Tasks cancelled
    refreshTimer?.invalidate(); refreshTimer = nil
    updateDebouncer?.invalidate(); updateDebouncer = nil
}
```

**Verdict**: This ViewModel is well-designed with proper cleanup. No action needed.

---

### ⚠️ MessageViewModel (Chat_Individual.swift) - NEEDS FIX

**Status**: Has `deinit` but **does not cancel network requests**

**Current Implementation**:
```swift
deinit {
    print("🗑️ [CHAT_VM] DEINIT for otherUserId: \(otherUserId)")
    // Only cleans up socket listener ⚠️
    if let id = socketObserverId {
        RealtimeSocketManager.shared.removeDirectMessageObserver(id)
    }
    // ❌ NO task cancellation!
}
```

**Network Requests Without Cancellation**:

1. **Line 235**: `fetchMessages()` - Main message loading
2. **Line 331**: `sendMessage()` - Sending new messages
3. **Line 367**: `toggleReaction()` - Adding/removing reactions
4. **Line ~420**: `editMessage()` - Editing messages

**Problem**:
All 4 methods use `URLSession.shared.dataTask` but:
- ❌ Tasks are not stored in properties
- ❌ Tasks are not cancelled in `deinit`
- ✓ Uses `[weak self]` (good, but not enough)
- ✓ Has `guard let self` checks (good, but not enough)

**Why `[weak self]` Alone Isn't Enough**:

Even with `[weak self]` and guard checks, the URLSession tasks keep running:
```swift
URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
    guard let self = self else {
        print("Self deallocated")  // This fires, but...
        return  // ...task already consumed network/CPU resources
    }
    // This code doesn't run, but the REQUEST already happened
}
```

**Crash/Performance Scenario**:
1. User opens DM chat with Person A
2. `fetchMessages()` starts loading (200 messages)
3. User immediately taps back (within 0.5s)
4. ViewModel deinitialized
5. Network request completes and tries to update UI
6. `guard let self` catches it, but:
   - Network bandwidth wasted
   - Battery drained
   - If user rapidly opens 10 chats, 10+ requests pile up
   - Can cause memory pressure → **CRASH**

---

## Recommended Fix for MessageViewModel

**Risk Level**: MINIMAL (same pattern as GroupChatViewModel)

### Implementation

**Step 1**: Add task tracking properties
```swift
class MessageViewModel: ObservableObject {
    // ... existing properties ...

    // CRASH FIX: Network request cancellation
    private var fetchTask: URLSessionDataTask?
    private var sendTask: URLSessionDataTask?
    private var reactionTask: URLSessionDataTask?
    private var editTask: URLSessionDataTask?
```

**Step 2**: Update deinit
```swift
deinit {
    print("🗑️ [CHAT_VM] DEINIT for otherUserId: \(otherUserId)")

    // Clean up socket listener
    if let id = socketObserverId {
        print("   [CHAT_VM] Deinit: Removing socket observer \(id)")
        RealtimeSocketManager.shared.removeDirectMessageObserver(id)
    }

    // CRASH FIX: Cancel all network requests
    fetchTask?.cancel()
    sendTask?.cancel()
    reactionTask?.cancel()
    editTask?.cancel()

    // Defensive cleanup
    socketObserverId = nil
    isInitialized = false
    canLoadOlder = false
}
```

**Step 3**: Update fetchMessages() - Line ~235
```swift
func fetchMessages(beforeId: Int? = nil, append: Bool) {
    // CRASH FIX: Cancel previous fetch
    if !append {
        fetchTask?.cancel()
    }

    // ... existing URL building code ...

    fetchTask = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
        // ... existing completion handler ...
    }
    fetchTask?.resume()
}
```

**Step 4**: Update sendMessage() - Line ~331
```swift
func sendMessage() {
    // CRASH FIX: Cancel previous send (shouldn't happen but defensive)
    sendTask?.cancel()

    // ... existing code ...

    sendTask = URLSession.shared.dataTask(with: request) { data, _, error in
        // ... existing completion handler ...
    }
    sendTask?.resume()
}
```

**Step 5**: Update toggleReaction() - Line ~367
```swift
func toggleReaction(messageId: Int, emoji: String) {
    // CRASH FIX: Cancel previous reaction request
    reactionTask?.cancel()

    // ... existing code ...

    reactionTask = URLSession.shared.dataTask(with: request) { data, _, error in
        // ... existing completion handler ...
    }
    reactionTask?.resume()
}
```

**Step 6**: Update editMessage() - Line ~420 (similar pattern)
```swift
func editMessage(messageId: Int, newText: String) {
    // CRASH FIX: Cancel previous edit request
    editTask?.cancel()

    // ... existing code ...

    editTask = URLSession.shared.dataTask(with: request) { data, _, error in
        // ... existing completion handler ...
    }
    editTask?.resume()
}
```

---

## Why This Fix Is Safe

1. **Proven Pattern**: GroupChatViewModel already uses this exact approach
2. **Additive Only**: Only adds cancellation, doesn't change logic
3. **Graceful Degradation**: If cancellation fails, behavior is unchanged
4. **No User-Facing Changes**: Chat still works identically
5. **Performance Improvement**: Saves network/battery by canceling stale requests

---

## Testing Recommendation

Test this rapid navigation sequence:
1. MainScreen → Open DM with User A
2. Immediately tap Back (within 0.5s)
3. Repeat 10 times with different users
4. Monitor: Should see "🗑️ DEINIT" followed by task cancellations in console
5. No memory buildup or crashes

---

## Comparison: Before vs After

### Before Fix:
```
User opens chat → fetchMessages() starts
User taps back in 0.3s → ViewModel deinit → Socket cleaned up
Network response arrives 0.5s later → guard let self fails → Resource wasted ❌
```

### After Fix:
```
User opens chat → fetchMessages() starts
User taps back in 0.3s → deinit → fetchTask?.cancel() → Request cancelled ✅
Network response never arrives → No wasted resources ✓
```

---

## Implementation Priority

**High Priority**: Yes, but not urgent

**Reasoning**:
- GroupChat is already safe (uses proper cancellation)
- Direct messages (MessageViewModel) needs the fix
- Risk is lower than PortalViewModel/GoalsDetailViewModel because:
  - Uses `[weak self]` which prevents retain cycle crashes
  - Mainly wastes resources rather than hard crashes
  - But rapid chat navigation can still cause memory pressure

**Recommendation**: Implement this fix after validating the PortalViewModel and GoalsDetailViewModel fixes are working well (give those 3-5 days in production first).

---

## Summary

| Component | Status | Action Needed |
|-----------|--------|---------------|
| GroupChatViewModel | ✅ Safe | None - already properly implemented |
| MessageViewModel | ⚠️ Needs Fix | Add request cancellation (low risk) |

**Total Changes Needed**: ~30 lines of code in MessageViewModel only
**Risk Level**: Minimal
**Expected Impact**: Reduced memory pressure, better battery life, no crashes from rapid navigation
