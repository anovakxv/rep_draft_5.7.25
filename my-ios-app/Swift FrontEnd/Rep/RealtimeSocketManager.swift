// RealtimeSocketManager.swift

import Foundation
import SocketIO

class RealtimeSocketManager {
    static let shared = RealtimeSocketManager()
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private var connected = false
    private var registeredEvents = false

    // NEW: track latest intended user id so we always join after (re)connect
    private var pendingUserId: Int?

    func connect(baseURL: String, token: String, userId: Int? = nil) {
        guard !token.isEmpty, let url = URL(string: baseURL) else { return }
        if let uid = userId { pendingUserId = uid }

        if manager == nil {
            manager = SocketManager(
                socketURL: url,
                config: [
                    .compress,
                    .connectParams(["token": token]),
                    .log(false)
                    // .forceWebsockets   // enable if long-poll fallback causes auth issues
                ]
            )
            socket = manager?.defaultSocket
            registerLifecycle()
            manager?.connect()
        } else {
            // If already created but now we know userId, and socket connected -> join immediately
            if socket?.status == .connected, let uid = pendingUserId {
                socket?.emit("join", ["room": "user_\(uid)"])
                print("🔗 (Realtime) Immediate join user_\(uid)")
            } else {
                // Not yet connected -> connection in flight; lifecycle will handle
                print("⏳ (Realtime) Will join user_\(pendingUserId ?? -1) after connect")
            }
        }
    }

    private func registerLifecycle() {
        socket?.on(clientEvent: .connect) { [weak self] _, _ in
            guard let self else { return }
            self.connected = true
            print("✅ (Realtime) Socket connected")
            if let uid = self.pendingUserId {
                print("➡️ (Realtime) Joining user_\(uid)")
                self.socket?.emit("join", ["room": "user_\(uid)"])
            } else {
                print("⚠️ (Realtime) No pendingUserId at connect")
            }
            self.registerCoreListeners()
        }
        socket?.on(clientEvent: .disconnect) { [weak self] data, _ in
            self?.connected = false
            print("❌ (Realtime) Disconnected:", data)
        }
    }

    private func registerCoreListeners() {
        guard !registeredEvents else { return }
        registeredEvents = true

        // TEMP instrumentation: log all socket events for debugging
        socket?.onAny { event in
            print("📡 (Socket ANY) \(event.event) -> \(event.items ?? [])")
        }

        socket?.on("goal_team_invite") { data, _ in
            NotificationCenter.default.post(name: .socketGoalTeamInvite, object: data.first as? [String: Any])
        }
        socket?.on("goal_team_invite_update") { data, _ in
            NotificationCenter.default.post(name: .socketGoalTeamInviteUpdate, object: data.first as? [String: Any])
        }
    }

    func onDirectMessageNotification(_ handler: @escaping ([String: Any]) -> Void) {
        print("🔧 (Realtime) Register DM listener")
        socket?.off("direct_message_notification")
        socket?.on("direct_message_notification") { data, _ in
            print("📲 (Realtime) direct_message_notification raw:", data)
            if let dict = data.first as? [String: Any] {
                handler(dict)
            } else if data.count > 0 {
                var combined: [String: Any] = [:]
                for item in data {
                    if let d = item as? [String: Any] {
                        for (k, v) in d { combined[k] = v }
                    }
                }
                if !combined.isEmpty { handler(combined) }
            }
        }
    }

    func onGroupMessage(_ handler: @escaping ([String: Any]) -> Void) {
        socket?.off("group_message")
        socket?.on("group_message") { data, _ in
            print("📡 (Realtime) group_message raw:", data)
            if let dict = data.first as? [String: Any] {
                handler(dict)
            }
        }
    }

    func join(chatId: Int) {
        socket?.emit("join", ["chat_id": chatId])
        print("➡️ (Realtime) join(chat_id: \(chatId)) emitted")
    }

    func leave(chatId: Int) {
        socket?.emit("leave", ["chat_id": chatId])
        print("⬅️ (Realtime) leave(chat_id: \(chatId)) emitted")
    }

    func disconnect() {
        manager?.disconnect()
        connected = false
        registeredEvents = false
    }

    func reconnectIfNeeded() {
        if socket?.status != .connected {
            manager?.reconnect()
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let socketGoalTeamInvite = Notification.Name("socketGoalTeamInvite")
    static let socketGoalTeamInviteUpdate = Notification.Name("socketGoalTeamInviteUpdate")
    static let socketDirectMessage = Notification.Name("socketDirectMessage") // optional if you want broadcast
}