import Foundation
import SocketIO

class RealtimeSocketManager {
    static let shared = RealtimeSocketManager()
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private var connected = false

    func connect(baseURL: String, token: String) {
        guard !connected else { return }
        guard let url = URL(string: baseURL) else { return }
        manager = SocketManager(socketURL: url, config: [.compress, .connectParams(["token": token]), .log(false)])
        socket = manager?.defaultSocket
        socket?.on(clientEvent: .connect) { _, _ in
            self.connected = true
        }
        socket?.on(clientEvent: .disconnect) { _, _ in
            self.connected = false
        }
        manager?.connect()
    }

    func join(chatId: Int) {
        socket?.emit("join", ["chat_id": chatId])
    }

    func leave(chatId: Int) {
        socket?.emit("leave", ["chat_id": chatId])
    }

    func onGroupMessage(_ handler: @escaping ([String: Any]) -> Void) {
        socket?.on("group_message") { data, _ in
            if let dict = data.first as? [String: Any] {
                handler(dict)
            }
        }
    }
}
