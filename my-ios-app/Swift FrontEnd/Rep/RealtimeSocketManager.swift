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
                ]
            )
            socket = manager?.defaultSocket
            registerLifecycle(userId: userId)
            manager?.connect()
        } else if socket?.status == .connected, let userId {
            // Re-emit user room join in case it was missed
            socket?.emit("join", ["room": "user_\(userId)"])
        }
    }

    private func registerLifecycle(userId: Int?) {
        socket?.on(clientEvent: .connect) { [weak self] _, _ in
            guard let self else { return }
            self.connected = true
            if let userId = userId {
                self.socket?.emit("join", ["room": "user_\(userId)"]) // requires server support
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
    }

    func onDirectMessageNotification(_ handler: @escaping ([String: Any]) -> Void) {
        socket?.off("direct_message_notification")
        socket?.on("direct_message_notification") { data, _ in
            print("📲 Socket received direct_message_notification: \(data)")
            if let dict = data.first as? [String: Any] {
                handler(dict)
            } else if data.count > 0 {
                // Try alternative format - sometimes Socket.IO has different payload formats
                print("⚠️ Socket data format unexpected, trying alternative parser")
                var combinedDict: [String: Any] = [:]
                for item in data {
                    if let dict = item as? [String: Any] {
                        for (key, value) in dict {
                            combinedDict[key] = value
                        }
                    }
                }
                if !combinedDict.isEmpty {
                    handler(combinedDict)
                }
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