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

    // Callback registries (multiple listeners supported)
    private var dmCallbacks: [([String: Any]) -> Void] = []
    private var groupCallbacks: [([String: Any]) -> Void] = []

    // MARK: - Public Connect

    func connect(baseURL: String, token: String, userId: Int) {
        guard !baseURL.isEmpty, !token.isEmpty, userId != 0 else { return }
        pendingUserId = userId

        // Normalize: strip trailing "/api" if present
        let normalizedURL = baseURL.hasSuffix("/api") ? String(baseURL.dropLast(4)) : baseURL

        // If already connected with same context, just ensure user room joined
        if let _ = socket, isConnected,
           lastBaseURL == normalizedURL, lastToken == token, lastUserId == userId {
            joinUserRoom(userId: userId) // idempotent
            return
        }

        // If baseURL or token/user changed, rebuild manager
        if manager == nil ||
            lastBaseURL != normalizedURL ||
            lastToken != token {
            buildManager(baseURL: normalizedURL, token: token)
        }

        lastBaseURL = normalizedURL
        lastToken = token
        lastUserId = userId

        // Initiate (or re-)connect
        manager?.connect()
    }

    // Ensure personal room joined (safe to call anytime)
    func ensureUserRoomJoined(userId: Int) {
        pendingUserId = userId
        if isConnected {
            joinUserRoom(userId: userId)
        }
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
                .extraHeaders(["Authorization": "Bearer \(token)"]), // add header auth (polling/WebSocket fallbacks)
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
                self.fireDMCallbacks(dict)
            } else {
                // Attempt merge if fragmented payload
                var merged: [String: Any] = [:]
                data.forEach {
                    if let d = $0 as? [String: Any] {
                        d.forEach { merged[$0.key] = $0.value }
                    }
                }
                if !merged.isEmpty {
                    self.fireDMCallbacks(merged)
                }
            }
        }

        for evt in dmEventNames {
            socket.on(evt) { data, _ in dmHandler(data) }
        }

        // Group message event (used by GroupChatViewModel)
        socket.on("group_message") { [weak self] data, _ in
            guard let self else { return }
            guard let dict = data.first as? [String: Any] else { return }
            self.groupCallbacks.forEach { $0(dict) }
        }

        // Existing invite events (kept)
        socket.on("goal_team_invite") { data, _ in
            NotificationCenter.default.post(name: .socketGoalTeamInvite,
                                            object: data.first as? [String: Any])
        }
        socket.on("goal_team_invite_update") { data, _ in
            NotificationCenter.default.post(name: .socketGoalTeamInviteUpdate,
                                            object: data.first as? [String: Any])
        }
    }

    private func fireDMCallbacks(_ payload: [String: Any]) {
        dmCallbacks.forEach { $0(payload) }
        // Optional NotificationCenter broadcast if other parts need it
        NotificationCenter.default.post(name: .socketDirectMessage, object: payload)
    }

    // MARK: - Public Listener Registration (additive)

    func onDirectMessageNotification(_ cb: @escaping ([String: Any]) -> Void) {
        dmCallbacks.append(cb)
    }

    func onGroupMessage(_ cb: @escaping ([String: Any]) -> Void) {
        groupCallbacks.append(cb)
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
        socket?.emit("leave_group_chat", ["chat_id": chatId])
        socket?.emit("leave", ["chat_id": chatId]) // legacy fallback (kept for compatibility)
        print("⬅️ (Realtime) leave group chat \(chatId)")
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
        fireDMCallbacks(payload)
    }
    #endif
}

// MARK: - Notification Names

extension Notification.Name {
    static let socketGoalTeamInvite = Notification.Name("socketGoalTeamInvite")
    static let socketGoalTeamInviteUpdate = Notification.Name("socketGoalTeamInviteUpdate")
    static let socketDirectMessage = Notification.Name("socketDirectMessage")
}