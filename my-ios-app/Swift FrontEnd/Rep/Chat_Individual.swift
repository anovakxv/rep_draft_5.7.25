//  Rep
//
//  Created by Adam Novak on 06.19.2025
//  (c) 2025 Networked Capital Inc. All rights reserved.

import SwiftUI

// MARK: - Message Model

struct SimpleMessage: Identifiable, Decodable {
    let id: Int
    let senderId: Int
    let senderName: String
    let text: String
    let timestamp: Date
    let read: String?

    enum CodingKeys: String, CodingKey {
        case id
        case senderId = "sender_id"
        case senderName = "sender_name"
        case text
        case timestamp
        case read
    }
}

// MARK: - API Response Models

struct GetMessagesAPIResponse: Decodable {
    struct Result: Decodable {
        let messages: [SimpleMessage]
    }
    let result: Result
}

struct SendMessageAPIResponse: Decodable {
    let result: String
    let message: SimpleMessage
}

// MARK: - Messaging ViewModel

class MessageViewModel: ObservableObject {
    @Published var messages: [SimpleMessage] = []
    @Published var inputText: String = ""
    @Published var isLoadingOlder: Bool = false
    @Published var canLoadOlder: Bool = true   // optimistic until proven empty
    
    let currentUserId: Int
    let otherUserId: Int
    let otherUserName: String
    let otherUserPhotoURL: URL?
    
    @AppStorage("jwtToken") var jwtToken: String = ""
    
    init(currentUserId: Int, otherUserId: Int, otherUserName: String, otherUserPhotoURL: URL?) {
        self.currentUserId = currentUserId
        self.otherUserId = otherUserId
        self.otherUserName = otherUserName
        self.otherUserPhotoURL = otherUserPhotoURL
        
        // Realtime listener for THIS DM thread
        RealtimeSocketManager.shared.onDirectMessageNotification { [weak self] payload in
            guard let self = self else { return }
            let senderId = payload["sender_id"] as? Int ?? payload["senderId"] as? Int
            let recipientId = payload["recipient_id"] as? Int ?? payload["recipientId"] as? Int
            // Only if from the other user to me
            if senderId == self.otherUserId && recipientId == self.currentUserId {
                if let data = try? JSONSerialization.data(withJSONObject: payload) {
                    // Try full response shape first
                    if let decoded = try? JSONDecoder.withISO8601.decode(SendMessageAPIResponse.self, from: data) {
                        DispatchQueue.main.async {
                            self.appendIfNeeded(decoded.message)
                        }
                        return
                    }
                    // Fallback to single message
                    if let msg = try? JSONDecoder.withISO8601.decode(SimpleMessage.self, from: data) {
                        DispatchQueue.main.async {
                            self.appendIfNeeded(msg)
                        }
                    }
                }
            }
        }
    }
    
    private func appendIfNeeded(_ message: SimpleMessage) {
        if !messages.contains(where: { $0.id == message.id }) {
            messages.append(message)
            // Keep ascending order defensively
            messages.sort { $0.timestamp < $1.timestamp }
        }
    }
    
    // Fetch newest slice (initial or refresh)
    func fetchMessages() {
        fetchMessages(beforeId: nil, append: false)
    }
    
    // Unified fetch supporting older pagination
    func fetchMessages(beforeId: Int? = nil, append: Bool) {
        if append {
            guard !isLoadingOlder, canLoadOlder else { return }
            isLoadingOlder = true
        }
        
        var components = URLComponents(string: "\(APIConfig.baseURL)/api/message/get_messages")!
        var query: [URLQueryItem] = [
            .init(name: "users_id", value: "\(otherUserId)"),
            .init(name: "order", value: "ASC"),
            .init(name: "limit", value: "200"),
            .init(name: "mark_as_read", value: append ? "0" : "1") // only mark on main (latest) fetch
        ]
        if let bid = beforeId {
            query.append(.init(name: "before_id", value: "\(bid)"))
        }
        components.queryItems = query
        
        guard let url = components.url else { return }
        var request = URLRequest(url: url)
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if append {
                DispatchQueue.main.async { self.isLoadingOlder = false }
            }
            guard let data, error == nil else { return }
            let decoder = JSONDecoder.withISO8601
            guard let apiResult = try? decoder.decode(GetMessagesAPIResponse.self, from: data) else {
                print("Failed to decode messages: \(String(data: data, encoding: .utf8) ?? "")")
                return
            }
            let newMsgs = apiResult.result.messages.sorted { $0.timestamp < $1.timestamp }
            DispatchQueue.main.async {
                if append {
                    if newMsgs.isEmpty {
                        self.canLoadOlder = false
                    } else {
                        // Insert at top without duplicates
                        let existingIds = Set(self.messages.map { $0.id })
                        let filtered = newMsgs.filter { !existingIds.contains($0.id) }
                        self.messages.insert(contentsOf: filtered, at: 0)
                    }
                } else {
                    self.messages = newMsgs
                    // Notify to clear unread badge
                    NotificationCenter.default.post(name: Notification.Name("refreshActiveChats"), object: nil)
                }
            }
        }.resume()
    }
    
    func loadOlderIfNeeded(firstVisibleId: Int?) {
        guard let firstId = firstVisibleId else { return }
        // If the first currently loaded message is near top and we can load more
        if messages.first?.id == firstId {
            fetchMessages(beforeId: firstId, append: true)
        }
    }
    
    func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let url = URL(string: "\(APIConfig.baseURL)/api/message/send_message") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        let body: [String: Any] = [
            "users_id": otherUserId,
            "message": trimmed
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("Send message error: \(error)")
                return
            }
            guard let data else {
                print("No data returned from send message")
                return
            }
            let decoder = JSONDecoder.withISO8601
            if let apiResult = try? decoder.decode(SendMessageAPIResponse.self, from: data) {
                DispatchQueue.main.async {
                    self.appendIfNeeded(apiResult.message)
                    self.inputText = ""
                }
            } else {
                print("Failed to decode send message response: \(String(data: data, encoding: .utf8) ?? "")")
            }
        }.resume()
    }
}

// Helper decoder for ISO8601
extension JSONDecoder {
    static var withISO8601: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}

// MARK: - Messaging View

struct MessageView: View {
    @StateObject var viewModel: MessageViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            NavigationHeaderView(name: viewModel.otherUserName, onBack: { dismiss() })
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Load older trigger spacer
                        if viewModel.canLoadOlder {
                            Color.clear
                                .frame(height: 1)
                                .onAppear {
                                    // When top becomes visible, attempt to load older
                                    viewModel.loadOlderIfNeeded(firstVisibleId: viewModel.messages.first?.id)
                                }
                        }
                        ForEach(viewModel.messages) { message in
                            HStack(alignment: .bottom, spacing: 8) {
                                if message.senderId == viewModel.currentUserId {
                                    Spacer()
                                    MessageBubble(message: message, isCurrentUser: true, profilePicURL: nil)
                                } else {
                                    MessageBubble(message: message, isCurrentUser: false, profilePicURL: viewModel.otherUserPhotoURL)
                                    Spacer()
                                }
                            }
                        }
                        if viewModel.isLoadingOlder {
                            ProgressView()
                                .padding(.vertical, 8)
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                }
                .background(Color.white)
                .onChange(of: viewModel.messages.count) { _ in
                    // Scroll to bottom only when adding newer (not when prepending older)
                    if let last = viewModel.messages.last, !viewModel.isLoadingOlder {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            HStack(spacing: 8) {
                GrowingTextEditor(text: $viewModel.inputText)
                Button(action: {
                    viewModel.sendMessage()
                }) {
                    Text("Send")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 18)
                        .background(SwiftUI.Color.repGreen)
                        .cornerRadius(8)
                }
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(UIColor(red: 0.894, green: 0.894, blue: 0.894, alpha: 1.0))),
                alignment: .top
            )
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
        .onAppear {
            // Always fetch latest (marks as read server-side and posts refreshActiveChats)
            viewModel.fetchMessages()
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: SimpleMessage
    let isCurrentUser: Bool
    let profilePicURL: URL?
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isCurrentUser {
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(message.text)
                        .padding(10)
                        .background(Color.black)
                        .foregroundColor(Color.repGreen)
                        .cornerRadius(8)
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: 260, alignment: .trailing)
            } else {
                if let url = profilePicURL {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle().fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 32, height: 32)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(message.text)
                        .padding(10)
                        .background(Color(UIColor.systemGray5))
                        .foregroundColor(.black)
                        .cornerRadius(8)
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: 260, alignment: .leading)
                Spacer()
            }
        }
        .id(message.id)
    }
}

// MARK: - Preview

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        MessageView(
            viewModel: MessageViewModel(
                currentUserId: 1,
                otherUserId: 2,
                otherUserName: "Alex",
                otherUserPhotoURL: URL(string: "https://randomuser.me/api/portraits/men/32.jpg")
            )
        )
    }
}