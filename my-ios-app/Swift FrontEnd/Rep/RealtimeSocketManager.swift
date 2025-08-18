// RealtimeSocketManager.swift

import Foundation
import SocketIO

class RealtimeSocketManager {
    static let shared = RealtimeSocketManager()
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private var connected = false
    private var registeredEvents = false

    func connect(baseURL: String, token: String, userId: Int? = nil) {
        guard !token.isEmpty, let url = URL(string: baseURL) else { return }
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
            registerLifecycle(initialUserId: userId)
            manager?.connect()
        } else if socket?.status == .connected, let userId {
            socket?.emit("join", ["room": "user_\(userId)"])
        }
    }

    private func registerLifecycle(initialUserId: Int?) {
        socket?.on(clientEvent: .connect) { [weak self] _, _ in
            guard let self else { return }
            self.connected = true
            if let uid = initialUserId {
                self.socket?.emit("join", ["room": "user_\(uid)"])
            }
            self.registerCoreListeners()
        }
        socket?.on(clientEvent: .disconnect) { [weak self] _, _ in
            self?.connected = false
        }
    }

    private func registerCoreListeners() {
        guard !registeredEvents else { return }
        registeredEvents = true

        socket?.on("goal_team_invite") { data, _ in
            NotificationCenter.default.post(name: .socketGoalTeamInvite, object: data.first as? [String: Any])
        }
        socket?.on("goal_team_invite_update") { data, _ in
            NotificationCenter.default.post(name: .socketGoalTeamInviteUpdate, object: data.first as? [String: Any])
        }
    }

    func onDirectMessageNotification(_ handler: @escaping ([String: Any]) -> Void) {
        socket?.off("direct_message_notification")
        socket?.on("direct_message_notification") { data, _ in
            print("📲 Socket received direct_message_notification: \(data)")
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
            if let dict = data.first as? [String: Any] {
                handler(dict)
            }
        }
    }

    func join(chatId: Int) {
        socket?.emit("join", ["chat_id": chatId])
    }

    func leave(chatId: Int) {
        socket?.emit("leave", ["chat_id": chatId])
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