//  Rep
//
//  Created by Adam Novak on 06.19.2025
//  (c) 2025 Networked Capital Inc. All rights reserved.

import SwiftUI

// MARK: - Message Model

struct SimpleMessage: Identifiable, Decodable, Equatable {
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
    @Published var isInitialized: Bool = false  // Track initialization state

    let currentUserId: Int
    let otherUserId: Int
    let otherUserName: String
    let otherUserPhotoURL: URL?

    @AppStorage("jwtToken") var jwtToken: String = ""
    private var socketObserverId: UUID? = nil

    // --- FIX: Concurrency guards to prevent deadlocks ---
    private var isFetchingMessages = false
    private var isSettingUpSocket = false

    init(currentUserId: Int, otherUserId: Int, otherUserName: String, otherUserPhotoURL: URL?) {
        self.currentUserId = currentUserId
        self.otherUserId = otherUserId
        self.otherUserName = otherUserName
        self.otherUserPhotoURL = otherUserPhotoURL

        print("✅ [CHAT_VM] INIT for otherUserId: \(otherUserId)")

        // Start the initial fetch as soon as the view model is created.
        fetchMessages()
        
        // IMPORTANT: Delay socket setup until after UI is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.setupSocketListener()
        }
    }

    // Call this after view appears and initial messages load
    func setupSocketListener() {
        print("📞 [CHAT_VM] Attempting to setup socket listener...")
        guard !isSettingUpSocket else {
            print("⚠️ [CHAT_VM] Aborted: setupSocketListener() already in progress.")
            return
        }
        isSettingUpSocket = true

        // Remove any existing listener first
        if let id = socketObserverId {
            print("   [CHAT_VM] Removing existing socket observer: \(id)")
            RealtimeSocketManager.shared.removeDirectMessageObserver(id)
        }

        // Register new listener
        socketObserverId = RealtimeSocketManager.shared.onDirectMessageNotification { [weak self] payload in
            guard let self = self else { return }
            print("📡 [CHAT_VM] Received socket payload: \(payload)")
            let senderId = payload["sender_id"] as? Int ?? payload["senderId"] as? Int
            let recipientId = payload["recipient_id"] as? Int ?? payload["recipientId"] as? Int

            // Only process if from the other user to me
            if senderId == self.otherUserId && recipientId == self.currentUserId {
                print("   [CHAT_VM] Payload is relevant. Processing...")
                if let data = try? JSONSerialization.data(withJSONObject: payload) {
                    if let decoded = try? JSONDecoder.withISO8601.decode(SendMessageAPIResponse.self, from: data) {
                        DispatchQueue.main.async {
                            self.appendIfNeeded(decoded.message)
                        }
                        return
                    }
                    if let msg = try? JSONDecoder.withISO8601.decode(SimpleMessage.self, from: data) {
                        DispatchQueue.main.async {
                            self.appendIfNeeded(msg)
                        }
                    }
                }
            } else {
                print("   [CHAT_VM] Payload ignored (not for this conversation).")
            }
        }
        print("👍 [CHAT_VM] Socket listener setup complete. Observer ID: \(socketObserverId?.uuidString ?? "N/A")")
        isSettingUpSocket = false
    }

    deinit {
        print("🗑️ [CHAT_VM] DEINIT for otherUserId: \(otherUserId)")
        // Clean up listener when view model is deallocated
        if let id = socketObserverId {
            print("   [CHAT_VM] Deinit: Removing socket observer \(id)")
            RealtimeSocketManager.shared.removeDirectMessageObserver(id)
        }
        // Defensive cleanup
        socketObserverId = nil
        isInitialized = false
        canLoadOlder = false
    }

    private func appendIfNeeded(_ message: SimpleMessage) {
        if !messages.contains(where: { $0.id == message.id }) {
            print("   [CHAT_VM] Appending new message ID: \(message.id)")
            messages.append(message)
            // Keep ascending order defensively
            messages.sort { $0.timestamp < $1.timestamp }
        } else {
            print("   [CHAT_VM] Ignoring duplicate message ID: \(message.id)")
        }
    }

    // Fetch newest slice (initial or refresh)
    func fetchMessages() {
        fetchMessages(beforeId: nil, append: false)
    }

    // Unified fetch supporting older pagination
    func fetchMessages(beforeId: Int? = nil, append: Bool) {
        print("⬇️ [CHAT_VM] fetchMessages called. Append: \(append), BeforeID: \(beforeId ?? -1)")

        if append {
            guard !isLoadingOlder, canLoadOlder else {
                print("⚠️ [CHAT_VM] Aborted paginated fetch. isLoadingOlder: \(isLoadingOlder), canLoadOlder: \(canLoadOlder)")
                return
            }
            isLoadingOlder = true
        } else {
            // --- FIX: Concurrency Guard ---
            guard !isFetchingMessages else {
                print("⚠️ [CHAT_VM] Aborted initial fetch: Another fetch is already in progress.")
                return
            }
            isFetchingMessages = true
        }

        var components = URLComponents(string: "\(APIConfig.baseURL)/api/message/get_messages")!
        var query: [URLQueryItem] = [
            .init(name: "users_id", value: "\(otherUserId)"),
            .init(name: "order", value: "ASC"),
            .init(name: "limit", value: "200"),
            .init(name: "mark_as_read", value: append ? "0" : "1")
        ]
        if let bid = beforeId {
            query.append(.init(name: "before_id", value: "\(bid)"))
        }
        components.queryItems = query

        guard let url = components.url else {
            print("❌ [CHAT_VM] Invalid URL generated.")
            if !append {
                DispatchQueue.main.async {
                    self.messages = []
                    self.isInitialized = true
                    self.isFetchingMessages = false // Reset flag
                    // REMOVED: self.setupSocketListener()
                }
            }
            return
        }

        print("   [CHAT_VM] Fetching URL: \(url.absoluteString)")
        var request = URLRequest(url: url)
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }

        // Add timeout to prevent hanging
        request.timeoutInterval = 10 // Reduced timeout

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else {
                print("❌ [CHAT_VM] Self was deallocated before fetch completed.")
                return
            }

            // Always update loading state on the main thread
            DispatchQueue.main.async {
                if append {
                    self.isLoadingOlder = false
                } else {
                    self.isFetchingMessages = false // Reset flag
                }

                if let error = error {
                    print("❌ [CHAT_VM] Message fetch network error: \(error.localizedDescription)")
                    if !append {
                        self.messages = []
                        self.isInitialized = true
                        // REMOVED: self.setupSocketListener()
                    }
                    return
                }

                guard let data = data else {
                    print("❌ [CHAT_VM] Message fetch failed: No data returned.")
                    if !append {
                        self.messages = []
                        self.isInitialized = true
                        // REMOVED: self.setupSocketListener()
                    }
                    return
                }

                let decoder = JSONDecoder.withISO8601
                guard let apiResult = try? decoder.decode(GetMessagesAPIResponse.self, from: data) else {
                    print("❌ [CHAT_VM] Failed to decode messages: \(String(data: data, encoding: .utf8) ?? "Invalid data")")
                    if !append {
                        self.messages = []
                        self.isInitialized = true
                        // REMOVED: self.setupSocketListener()
                    }
                    return
                }

                print("✅ [CHAT_VM] Fetch successful. Received \(apiResult.result.messages.count) messages.")
                let newMsgs = apiResult.result.messages.sorted { $0.timestamp < $1.timestamp }

                if append {
                    if newMsgs.isEmpty {
                        print("   [CHAT_VM] No older messages found. Disabling pagination.")
                        self.canLoadOlder = false
                    } else {
                        let existingIds = Set(self.messages.map { $0.id })
                        let filtered = newMsgs.filter { !existingIds.contains($0.id) }
                        print("   [CHAT_VM] Prepending \(filtered.count) older messages.")
                        self.messages.insert(contentsOf: filtered, at: 0)
                    }
                } else {
                    self.messages = newMsgs
                    self.isInitialized = true
                    // REMOVED: socket setup call that was here
                    // REMOVED: Notification post that was causing a deadlock
                }
            }
        }.resume()
    }

    func loadOlderIfNeeded(firstVisibleId: Int?) {
        // --- FIX: Do not attempt to paginate if there are no messages ---
        guard !messages.isEmpty else { return }
        guard let firstId = firstVisibleId else { return }
        if messages.first?.id == firstId {
            print("🔝 [CHAT_VM] Top of list reached, loading older messages.")
            fetchMessages(beforeId: firstId, append: true)
        }
    }

    func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        print("⬆️ [CHAT_VM] Sending message...")
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
                print("❌ [CHAT_VM] Send message error: \(error)")
                return
            }
            guard let data else {
                print("❌ [CHAT_VM] No data returned from send message")
                return
            }
            let decoder = JSONDecoder.withISO8601
            if let apiResult = try? decoder.decode(SendMessageAPIResponse.self, from: data) {
                print("✅ [CHAT_VM] Send message successful.")
                DispatchQueue.main.async {
                    self.appendIfNeeded(apiResult.message)
                    self.inputText = ""
                }
            } else {
                print("❌ [CHAT_VM] Failed to decode send message response: \(String(data: data, encoding: .utf8) ?? "")")
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

    init(viewModel: MessageViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        print("🎨 [CHAT_VIEW] INIT")
    }

    var body: some View {
        VStack(spacing: 0) {
            NavigationHeaderView(name: viewModel.otherUserName, onBack: { dismiss() })

            if !viewModel.isInitialized {
                VStack {
                    Spacer()
                    ProgressView("Loading conversation...")
                        .padding()
                    Spacer()
                }
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // --- FIX: Only show pagination trigger if there are messages ---
                            if viewModel.canLoadOlder && !viewModel.messages.isEmpty {
                                Color.clear
                                    .frame(height: 1)
                                    .onAppear {
                                        print("🎨 [CHAT_VIEW] Pagination trigger appeared.")
                                        viewModel.loadOlderIfNeeded(firstVisibleId: viewModel.messages.first?.id)
                                    }
                            }
                            if viewModel.messages.isEmpty {
                                VStack(spacing: 12) {
                                    Text("No messages yet")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    Text("Start a conversation with \(viewModel.otherUserName)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
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
                    .onChange(of: viewModel.messages.count) { newCount in
                        print("🎨 [CHAT_VIEW] Message count changed to \(newCount). Scrolling to bottom.")
                        if let last = viewModel.messages.last, !viewModel.isLoadingOlder {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: Notification.Name("scrollToMessageBottom"))) { notif in
                        if let id = notif.object as? Int {
                            withAnimation {
                                proxy.scrollTo(id, anchor: .bottom)
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
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
        .onAppear {
            print("🎨 [CHAT_VIEW] ON_APPEAR")
            // Scroll to bottom after a short delay to ensure view is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                if viewModel.isInitialized, let last = viewModel.messages.last {
                    NotificationCenter.default.post(name: Notification.Name("scrollToMessageBottom"), object: last.id)
                }
            }
        }
        .onDisappear {
            print("🎨 [CHAT_VIEW] ON_DISAPPEAR")
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