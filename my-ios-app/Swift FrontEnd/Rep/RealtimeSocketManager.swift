// RealtimeSocketManager.swift

import Foundation
import SocketIO

final class RealtimeSocketManager {
    static let shared = RealtimeSocketManager()

    private var manager: SocketManager?
    private var socket: SocketIOClient?

    private(set) var isConnected = false
    private var handlersRegistered = false

    // Track last successful connection parameters for reuse / dedupe
    private var lastBaseURL: String?
    private var lastToken: String?
    private var lastUserId: Int?

    // Pending (desired) identity for (re)join
    private var pendingUserId: Int?

    // MARK: - Observer storage (multicast, non-breaking)
    private struct DMObserver {
        let id: UUID
        let cb: ([String: Any]) -> Void
    }
    private struct GroupObserver {
        let id: UUID
        let cb: ([String: Any]) -> Void
    }
    // NEW: group notification observers for personal room
    private struct GroupNotifObserver {
        let id: UUID
        let cb: ([String: Any]) -> Void
    }
    private var dmObservers: [DMObserver] = []
    private var groupObservers: [GroupObserver] = []
    private var groupNotifObservers: [GroupNotifObserver] = []

    // MARK: - Public Connect

    func connect(baseURL: String, token: String, userId: Int) {
        guard !baseURL.isEmpty, !token.isEmpty, userId != 0 else { return }
        pendingUserId = userId

        // Normalize: strip trailing "/api" if present
        let normalizedURL = baseURL.hasSuffix("/api") ? String(baseURL.dropLast(4)) : baseURL

        // If already connected with same baseURL/token, only ensure room join (even if userId changed)
        if let _ = socket, isConnected,
           lastBaseURL == normalizedURL, lastToken == token {
            if lastUserId != userId {
                lastUserId = userId
            }
            joinUserRoom(userId: userId) // idempotent
            return
        }

        // If baseURL or token changed, rebuild manager
        if manager == nil ||
            lastBaseURL != normalizedURL ||
            lastToken != token {
            buildManager(baseURL: normalizedURL, token: token)
        }

        lastBaseURL = normalizedURL
        lastToken = token
        lastUserId = userId

        // Initiate connect on the default socket
        socket?.connect()
    }

    // Ensure personal room joined (safe to call anytime)
    func ensureUserRoomJoined(userId: Int) {
        pendingUserId = userId
        if isConnected {
            joinUserRoom(userId: userId)
        }
    }

    func cleanupAllHandlers() {
        // Completely reset all handlers to prevent duplicates
        if let socket = socket {
            socket.off("group_message")
            socket.off("group_message_notification")
            socket.off("direct_message")
            socket.off("direct_message_notification")
            
            // Only if we're still connected, re-register core handlers
            if socket.status == .connected && handlersRegistered {
                registerEventHandlersIfNeeded()
            }
        }
        
        // Reset state trackers
        dmObservers = []
        groupObservers = []
        groupNotifObservers = []
        
        print("🧹 (Realtime) All handlers cleaned up")
    }

    // MARK: - Build / Lifecycle

    private func buildManager(baseURL: String, token: String) {
        guard let url = URL(string: baseURL) else { return }

        // Tear down old (if any)
        manager?.disconnect()

        manager = SocketManager(
            socketURL: url,
            config: [
                .compress,
                .connectParams(["token": token]),
                .extraHeaders(["Authorization": "Bearer \(token)"]), // header auth (polling/WebSocket)
                .reconnects(true),
                .reconnectAttempts(-1),
                .reconnectWait(1),
                .reconnectWaitMax(20),
                .forceNew(true),
                .log(false)
            ]
        )
        socket = manager?.defaultSocket
        handlersRegistered = false
        registerLifecycle()
    }

    private func registerLifecycle() {
        guard let socket else { return }

        socket.on(clientEvent: .connect) { [weak self] _, _ in
            guard let self else { return }
            self.isConnected = true
            print("✅ (Realtime) Connected -> \(self.lastBaseURL ?? "")")
            if let uid = self.pendingUserId {
                self.joinUserRoom(userId: uid)
            } else {
                print("⚠️ (Realtime) No pending user id at connect")
            }
            self.registerEventHandlersIfNeeded()
        }

        socket.on(clientEvent: .disconnect) { [weak self] data, _ in
            guard let self else { return }
            self.isConnected = false
            print("❌ (Realtime) Disconnected: \(data)")
        }

        socket.on(clientEvent: .error) { data, _ in
            print("⚠️ (Realtime) Error: \(data)")
        }

        socket.on(clientEvent: .reconnect) { data, _ in
            print("🔄 (Realtime) Reconnect: \(data)")
        }

        // Generic debug (filter noisy 'ping')
        socket.onAny { event in
            if event.event != "ping" {
                print("📡 (Realtime ANY) \(event.event) items=\(event.items ?? [])")
            }
        }
    }

    // MARK: - Event Wiring

    private func registerEventHandlersIfNeeded() {
        guard !handlersRegistered, let socket else { return }
        handlersRegistered = true
        print("🧩 (Realtime) Registering event handlers")

        // Direct message events: support multiple possible names
        let dmEventNames = [
            "direct_message_notification",
            "new_direct_message",
            "direct_message",
            "dm_notification"
        ]

        let dmHandler: ([Any]) -> Void = { [weak self] data in
            guard let self else { return }
            if let dict = data.first as? [String: Any] {
                self.notifyDirectMessage(dict)
            } else {
                // Attempt merge if fragmented payload
                var merged: [String: Any] = [:]
                data.forEach {
                    if let d = $0 as? [String: Any] {
                        d.forEach { merged[$0.key] = $0.value }
                    }
                }
                if !merged.isEmpty {
                    self.notifyDirectMessage(merged)
                }
            }
        }

        for evt in dmEventNames {
            socket.on(evt) { data, _ in dmHandler(data) }
        }

        // Group message event (used by GroupChatViewModel and OPEN list refresh)
        socket.on("group_message") { [weak self] data, _ in
            guard let self else { return }
            guard let dict = data.first as? [String: Any] else { return }
            self.groupObservers.forEach { $0.cb(dict) }
        }

        // NEW: group notification to personal room (for OPEN dot)
        socket.on("group_message_notification") { [weak self] data, _ in
            guard let self else { return }
            guard let dict = data.first as? [String: Any] else { return }
            self.groupNotifObservers.forEach { $0.cb(dict) }
        }

        // Invite events (broadcast via NotificationCenter)
        socket.on("goal_team_invite") { data, _ in
            NotificationCenter.default.post(name: .socketGoalTeamInvite,
                                            object: data.first as? [String: Any])
        }
        socket.on("goal_team_invite_update") { data, _ in
            NotificationCenter.default.post(name: .socketGoalTeamInviteUpdate,
                                            object: data.first as? [String: Any])
        }
    }

    // MARK: - Notify helpers

    private func notifyDirectMessage(_ payload: [String: Any]) {
        dmObservers.forEach { $0.cb(payload) }
        // Optional NotificationCenter broadcast for any other listeners
        NotificationCenter.default.post(name: .socketDirectMessage, object: payload)
    }

    // MARK: - Public Listener Registration (additive, non-breaking)

    // Non-breaking change: returns UUID but callers can ignore
    @discardableResult
    func onDirectMessageNotification(_ cb: @escaping ([String: Any]) -> Void) -> UUID {
        let id = UUID()
        dmObservers.append(DMObserver(id: id, cb: cb))
        return id
    }

    func removeDirectMessageObserver(_ id: UUID) {
        dmObservers.removeAll { $0.id == id }
    }

    @discardableResult
    func onGroupMessage(_ cb: @escaping ([String: Any]) -> Void) -> UUID {
        let id = UUID()
        groupObservers.append(GroupObserver(id: id, cb: cb))
        return id
    }

    func removeGroupMessageObserver(_ id: UUID) {
        groupObservers.removeAll { $0.id == id }
    }

    // NEW: group_message_notification registration
    @discardableResult
    func onGroupMessageNotification(_ cb: @escaping ([String: Any]) -> Void) -> UUID {
        let id = UUID()
        groupNotifObservers.append(GroupNotifObserver(id: id, cb: cb))
        return id
    }

    func removeGroupMessageNotificationObserver(_ id: UUID) {
        groupNotifObservers.removeAll { $0.id == id }
    }

    // MARK: - Room Management

    private func joinUserRoom(userId: Int) {
        // Prefer explicit event; fallback legacy 'join'
        socket?.emit("join_user_room", ["user_id": userId])
        socket?.emit("join", ["room": "user_\(userId)"]) // backward compatibility
        print("➡️ (Realtime) join_user_room user_\(userId)")
    }

    func join(chatId: Int) {
        socket?.emit("join_group_chat", ["chat_id": chatId])
        socket?.emit("join", ["chat_id": chatId]) // legacy fallback (kept for compatibility)
        print("➡️ (Realtime) join group chat \(chatId)")
    }

    func leave(chatId: Int) {
        // First, emit both legacy and new events to leave room
        socket?.emit("leave_group_chat", ["chat_id": chatId])
        socket?.emit("leave", ["chat_id": chatId])
        print("⬅️ (Realtime) leave group chat \(chatId)")
        
        // Store observers that don't match this chat ID
        // We'll create a simple utility to check if a payload matches our chat
        func payloadMatchesChat(_ payload: [String: Any], chatId: Int) -> Bool {
            let chatAny = payload["chat_id"] ?? payload["chatId"]
            let payloadChatId = (chatAny as? Int) ?? (chatAny as? NSNumber)?.intValue ?? Int((chatAny as? String) ?? "") ?? -1
            return payloadChatId == chatId
        }
        
        // Remove any observer whose callback was likely for this chat
        // This is an approximation since we can't inspect closures directly
        for observer in groupObservers {
            if let payload = ["chat_id": chatId] as? [String: Any], 
            payloadMatchesChat(payload, chatId: chatId) {
                removeGroupMessageObserver(observer.id)
            }
        }
        
        // Also reset all pending handlers to avoid any race conditions
        socket?.off("group_message")
        
        // Re-register group message event (with new closures)
        if handlersRegistered, let socket = socket {
            socket.on("group_message") { [weak self] data, _ in
                guard let self = self else { return }
                guard let dict = data.first as? [String: Any] else { return }
                self.groupObservers.forEach { $0.cb(dict) }
            }
        }
    }

    // MARK: - Connection Control

    func disconnect() {
        manager?.disconnect()
        isConnected = false
    }

    func reconnectIfNeeded() {
        guard let socket else { return }
        if socket.status != .connected && socket.status != .connecting {
            print("🔄 (Realtime) Reconnecting...")
            socket.connect()
        }
    }

    // MARK: - Test Helpers (Local Only)

    #if DEBUG
    func simulateIncomingDirect(senderId: Int, recipientId: Int, text: String) {
        let payload: [String: Any] = [
            "message_id": Int.random(in: 100000...999999),
            "sender_id": senderId,
            "recipient_id": recipientId,
            "text": text,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "read": "0"
        ]
        notifyDirectMessage(payload)
    }
    #endif
}

// MARK: - Notification Names

extension Notification.Name {
    static let socketGoalTeamInvite = Notification.Name("socketGoalTeamInvite")
    static let socketGoalTeamInviteUpdate = Notification.Name("socketGoalTeamInviteUpdate")
    static let socketDirectMessage = Notification.Name("socketDirectMessage")
}