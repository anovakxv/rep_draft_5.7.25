//  GroupChatView.swift
//  Rep
//
//  Created by Adam Novak on 06.19.2025
//  (c) 2025 Networked Capital Inc. All rights reserved.

import SwiftUI

// MARK: - AnyDecodable (for dynamic JSON parsing)

struct AnyDecodable: Decodable {
    let value: Any
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            value = intVal
        } else if let strVal = try? container.decode(String.self) {
            value = strVal
        } else if let dictVal = try? container.decode([String: AnyDecodable].self) {
            value = dictVal.mapValues { $0.value }
        } else if let arrVal = try? container.decode([AnyDecodable].self) {
            value = arrVal.map { $0.value }
        } else {
            throw DecodingError.typeMismatch(AnyDecodable.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type in AnyDecodable"))
        }
    }
}

// MARK: - Shared Profile Picture Helper

fileprivate let s3BaseURL = "https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/"

fileprivate func patchProfilePictureURL(_ imageName: String?) -> URL? {
    guard let imageName = imageName, !imageName.isEmpty else { return nil }
    if imageName.starts(with: "http") {
        return URL(string: imageName)
    } else {
        return URL(string: s3BaseURL + imageName)
    }
}

struct ErrorMessage: Identifiable {
    let id = UUID()
    let message: String
}

// MARK: - Asset Host Helper

extension APIConfig {
    static var assetHost: String {
        if baseURL.hasSuffix("/api") {
            return String(baseURL.dropLast(4))
        }
        return baseURL
    }
}

extension Notification.Name {
    static let oneTimeRefreshActiveChats = Notification.Name("oneTimeRefreshActiveChats")
}

// MARK: - Group Message Model

struct GroupMessage: Identifiable, Decodable {
    let id: Int
    let senderId: Int
    let senderName: String
    let senderPhoto: String?
    let text: String
    let timestamp: Date

    var senderPhotoURL: URL? {
        patchProfilePictureURL(senderPhoto)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case senderId = "sender_id"
        case senderName = "sender_name"
        case senderPhoto = "sender_photo_url"
        case text
        case timestamp
        case createdAt = "created_at"
    }

    private static let isoWithFrac: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let isoNoFrac: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        senderId = try c.decode(Int.self, forKey: .senderId)
        senderName = (try? c.decode(String.self, forKey: .senderName)) ?? ""
        senderPhoto = try? c.decodeIfPresent(String.self, forKey: .senderPhoto)
        text = try c.decode(String.self, forKey: .text)
        let rawDate = (try? c.decodeIfPresent(String.self, forKey: .timestamp))
                   ?? (try? c.decodeIfPresent(String.self, forKey: .createdAt))
                   ?? ""
        if let d = GroupMessage.isoWithFrac.date(from: rawDate)
            ?? GroupMessage.isoNoFrac.date(from: rawDate) {
            timestamp = d
        } else {
            timestamp = Date()
        }
    }
}

// MARK: - Group Member Model

struct GroupMember: Identifiable, Decodable {
    let id: Int
    let name: String
    let profilePicture: String?

    var photoURL: URL? {
        patchProfilePictureURL(profilePicture)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name = "full_name"
        case profilePicture = "profile_picture_url"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        name = (try? c.decode(String.self, forKey: .name)) ?? ""
        profilePicture = try? c.decodeIfPresent(String.self, forKey: .profilePicture)
    }
}

// MARK: - API Response Models

struct GroupChatAPIResponse: Decodable {
    struct Result: Decodable {
        let chat: ChatInfo
        let users: [GroupMember]
        let messages: [GroupMessage]
    }
    let result: Result
}

struct ChatInfo: Decodable {
    let id: Int
    let name: String
    let description: String?
    let createdBy: Int

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case createdBy = "created_by"
    }
}

struct SendGroupMessageAPIResponse: Decodable {
    let result: String
    let message: GroupMessage
}

extension String: Identifiable {
    public var id: String { self }
}

struct NTWKUsersAPIResponse: Decodable {
    let result: [User]
}

// MARK: - Group Chat ViewModel

class GroupChatViewModel: ObservableObject {
    @Published var messages: [GroupMessage] = []
    @Published var inputText: String = ""
    @Published var groupMembers: [GroupMember] = []
    @Published var groupName: String = ""
    @Published var chatCreatorId: Int?
    @Published var isCreator: Bool = false
    @Published var errorMessage: ErrorMessage?

    private var loadMessagesTask: Task<Void, Never>?
    private var refreshTimer: Timer?

    let currentUserId: Int
    let chatId: Int
    let customChatTitle: String?

    @AppStorage("jwtToken") var jwtToken: String = ""

    // NEW: keep track of the socket observer to avoid duplicates
    private var groupObsId: UUID?
    private var groupNotifObsId: UUID?
    private var messageFetchTask: Task<Void, Never>?
    private var updateDebouncer: Timer?
    private var isRefreshing = false

    private var isPreviewInstance: Bool = false
    private(set) var isActive: Bool = false
    private var pendingLeaveWork: DispatchWorkItem?

    init(currentUserId: Int, chatId: Int, customChatTitle: String? = nil, isPreview: Bool = false) {
        self.currentUserId = currentUserId
        self.chatId = chatId
        self.customChatTitle = customChatTitle
        self.isPreviewInstance = isPreview
        if isPreview {
            print("👀 GroupChatViewModel init (preview) chat_\(chatId)")
        } else {
            print("✨ GroupChatViewModel init chat_\(chatId)")
        }
    }

    deinit {
        print("🧹 GroupChatViewModel deinit chat_\(chatId) active=\(isActive)")
        if isActive { performImmediateCleanup() }
    }

    func activate() {
        guard !isPreviewInstance else { return }
        pendingLeaveWork?.cancel(); pendingLeaveWork = nil
        guard !isActive else {
            print("⚙️ activate() ignored (already active) chat_\(chatId)")
            return
        }
        isActive = true
        print("🚀 activate() chat_\(chatId)")
        RealtimeSocketManager.shared.registerActiveChat(chatId: chatId)
        fetchGroupChat()
        setupRealtime()
    }

    func deactivate(reason: String = "onDisappear") {
        guard isActive else {
            print("⚙️ deactivate() ignored (already inactive) chat_\(chatId)")
            return
        }
        isActive = false
        print("🛑 deactivate() chat_\(chatId) reason=\(reason) – scheduling delayed leave")
        RealtimeSocketManager.shared.unregisterActiveChat(chatId: chatId)
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            if !self.isActive { // still inactive after grace period
                print("📤 leaving chat_\(self.chatId) after grace period")
                RealtimeSocketManager.shared.leaveGroupChat(chatId: self.chatId)
                self.performImmediateCleanup()
            } else {
                print("♻️ Skip leave for chat_\(self.chatId) – reactivated during grace period")
            }
        }
        pendingLeaveWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
    }

    private func performImmediateCleanup() {
        if let id = groupObsId { RealtimeSocketManager.shared.removeGroupMessageObserver(id); groupObsId = nil }
        if let id = groupNotifObsId { RealtimeSocketManager.shared.removeGroupMessageNotificationObserver(id); groupNotifObsId = nil }
        loadMessagesTask?.cancel(); loadMessagesTask = nil
        refreshTimer?.invalidate(); refreshTimer = nil
        updateDebouncer?.invalidate(); updateDebouncer = nil
    }

    // Legacy compatibility
    func teardownRealtime() { deactivate(reason: "legacy_teardown") }

    private func setupRealtime() {
        guard !jwtToken.isEmpty else { return }
        RealtimeSocketManager.shared.connect(baseURL: APIConfig.baseURL, token: jwtToken, userId: currentUserId)

        // Remove any existing observers before adding new ones (prevents duplicates)
        if let id = groupObsId {
            RealtimeSocketManager.shared.removeGroupMessageObserver(id)
            groupObsId = nil
        }
        if let id = groupNotifObsId {
            RealtimeSocketManager.shared.removeGroupMessageNotificationObserver(id)
            groupNotifObsId = nil
        }

        // Add new group message observer
        groupObsId = RealtimeSocketManager.shared.onGroupMessage { [weak self] payload in
            guard let self = self else { return }
            print("🧩 (GroupRT) Incoming group_message payload:", payload)

            // Robust chat_id parsing (supports Int/String/NSNumber and "chat_id"/"chatId")
            let chatAny = payload["chat_id"] ?? payload["chatId"]
            let incomingChatId = (chatAny as? Int)
                ?? (chatAny as? NSNumber)?.intValue
                ?? Int((chatAny as? String) ?? "")
            guard incomingChatId == self.chatId else { return }

            if let data = try? JSONSerialization.data(withJSONObject: payload),
            let msg = try? JSONDecoder().decode(GroupMessage.self, from: data) {
                DispatchQueue.main.async {
                    if !self.messages.contains(where: { $0.id == msg.id }) {
                        if let idx = self.messages.firstIndex(where: { $0.id < 0 && $0.text == msg.text && $0.senderId == msg.senderId }) {
                            self.messages[idx] = msg
                        } else {
                            self.messages.append(msg)
                        }
                    }
                }

                // If someone else sent it while we're viewing, mark read immediately and refresh OPEN
                if msg.senderId != self.currentUserId {
                    self.markCurrentChatReadIfNeeded(latestMessageId: msg.id)
                }
            }
        }

        // Add new group message notification observer (if needed for future use)
        groupNotifObsId = RealtimeSocketManager.shared.onGroupMessageNotification { [weak self] payload in
            // Handle notification if needed
        }

        // Delay join slightly to avoid racing the socket handshake; only if still active
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self, self.isActive else { return }
            RealtimeSocketManager.shared.join(chatId: self.chatId)
            print("➡️ (GroupRT) Requested join for chat_\(self.chatId)")
        }
    }

    // NEW: silence unused param warning (we still accept the id for future use)
    private func markCurrentChatReadIfNeeded(latestMessageId _: Int) {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/message/group_chat?chats_id=\(chatId)&limit=1") else { return }
        var request = URLRequest(url: url)
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        URLSession.shared.dataTask(with: request) { _, _, _ in
            // The server marks the chat as read. No client-side action needed here.
            // The active chats list will be refreshed when the user navigates back.
        }.resume()
    }

    func fetchGroupChat() {
        // Prevent overlapping refreshes
        guard !isRefreshing else {
            print("⚠️ Already refreshing chat \(chatId), skipping.")
            return
        }
        isRefreshing = true
        print("⏳ Starting fetch for chat_\(chatId)")

        // Cancel any existing debouncer
        updateDebouncer?.invalidate()

        guard let url = URL(string: "\(APIConfig.baseURL)/api/message/group_chat?chats_id=\(chatId)&limit=50") else {
            DispatchQueue.main.async {
                self.isRefreshing = false
            }
            return
        }
        var request = URLRequest(url: url)
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            // Ensure we are still on the main thread for UI updates
            DispatchQueue.main.async {
                guard let self = self else { return }

                // ALWAYS ensure isRefreshing is reset
                defer { self.isRefreshing = false }

                print("✅ Fetch completion for chat_\(self.chatId)")

                if let error = error {
                    self.errorMessage = ErrorMessage(message: "Network error: \(error.localizedDescription)")
                    return
                }

                guard let data = data else {
                    self.errorMessage = ErrorMessage(message: "No data received from server.")
                    return
                }

                do {
                    let decodedResponse = try JSONDecoder().decode(GroupChatAPIResponse.self, from: data)
                    self.messages = decodedResponse.result.messages.sorted { $0.timestamp < $1.timestamp }
                    self.groupMembers = decodedResponse.result.users
                    self.groupName = decodedResponse.result.chat.name
                    self.chatCreatorId = decodedResponse.result.chat.createdBy
                    self.isCreator = (self.currentUserId == self.chatCreatorId)

                    if let latest = self.messages.last {
                        self.markCurrentChatReadIfNeeded(latestMessageId: latest.id)
                    }
                } catch {
                    self.errorMessage = ErrorMessage(message: "Failed to decode chat data: \(error.localizedDescription)")
                }
            }
        }.resume()
    }    
    
    func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let url = URL(string: "\(APIConfig.baseURL)/api/message/send_chat_message") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        let body: [String: Any] = [
            "chats_id": chatId,
            "message": trimmed
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let tempId = -(messages.count + 1)
        let optimistic = GroupMessagePlaceholder.make(id: tempId, senderId: currentUserId, text: trimmed)
        DispatchQueue.main.async {
            self.messages.append(optimistic)
            self.inputText = ""
        }

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else { return }
            if let decoded = try? JSONDecoder().decode(SendGroupMessageAPIResponse.self, from: data) {
                let real = decoded.message
                DispatchQueue.main.async {
                    if let idx = self.messages.firstIndex(where: { $0.id == tempId }) {
                        self.messages[idx] = real
                    } else if !self.messages.contains(where: { $0.id == real.id }) {
                        self.messages.append(real)
                    }
                }
            }
        }.resume()
    }
}

// MARK: - Initials Helper

func initials(for name: String) -> String {
    let comps = name.split(separator: " ")
    let first = comps.first?.first.map { String($0) } ?? ""
    let last = comps.dropFirst().first?.first.map { String($0) } ?? ""
    return (first + last).uppercased()
}

// MARK: - Group Member Avatar View

struct GroupMemberAvatar: View {
    let name: String
    let photoURL: URL?
    var size: CGFloat = 36

    var body: some View {
        ZStack {
            if let url = photoURL {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.3))
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: size, height: size)
                Text(initials(for: name))
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Custom Navigation Header

struct GroupChatNavigationHeaderView: View {
    let name: String
    let onBack: () -> Void
    let onPlus: (() -> Void)?

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.black)
            }
            Spacer()
            Text(name)
                .font(.headline)
                .foregroundColor(.black)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer()
            if let onPlus = onPlus {
                Button(action: onPlus) {
                    Image(systemName: "plus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 2)
    }
}

// MARK: - Message Row

private struct GroupMessageRow: View {
    let message: GroupMessage
    let isCurrentUser: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isCurrentUser {
                Spacer()
                GroupMessageBubble(message: message, isCurrentUser: true)
            } else {
                GroupMessageBubble(message: message, isCurrentUser: false)
                Spacer()
            }
        }
        .id(message.id)
    }
}

// MARK: - Messages List

private struct GroupMessagesListView: View {
    let messages: [GroupMessage]
    let currentUserId: Int

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        GroupMessageRow(
                            message: message,
                            isCurrentUser: message.senderId == currentUserId
                        )
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
            }
            .background(Color.white)
            // NEW: scroll to bottom on initial appear
            .onAppear {
                if let lastId = messages.last?.id {
                    DispatchQueue.main.async {
                        withAnimation { proxy.scrollTo(lastId, anchor: .bottom) }
                    }
                }
            }
            // Keep auto-scrolling on new messages
            .onChange(of: messages.last?.id) { lastId in
                guard let lastId = lastId else { return }
                DispatchQueue.main.async {
                    withAnimation { proxy.scrollTo(lastId, anchor: .bottom) }
                }
            }
        }
    }
}

// MARK: - Group Chat View

struct GroupChatView: View {
    @StateObject var viewModel: GroupChatViewModel
    @State private var isNewlyCreatedChat: Bool

    init(viewModel: GroupChatViewModel, isNewlyCreated: Bool = false) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _isNewlyCreatedChat = State(initialValue: isNewlyCreated)
    }

    @Environment(\.dismiss) private var dismiss
    @State private var showEditSheet = false
    @State private var newChatId: Int? = nil
    @State private var navigateToNewChat = false
    @State private var chatDeleted = false

    private var newChatDestination: AnyView {
        if let newChatId = newChatId {
            return AnyView(
                GroupChatView(
                    viewModel: GroupChatViewModel(
                        currentUserId: viewModel.currentUserId,
                        chatId: newChatId
                    )
                )
            )
        } else {
            return AnyView(EmptyView())
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            GroupChatNavigationHeaderView(
                name: viewModel.customChatTitle ?? viewModel.groupName,
                onBack: { dismiss() },
                onPlus: { showEditSheet = true }
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.groupMembers) { member in
                        VStack {
                            GroupMemberAvatar(name: member.name, photoURL: member.photoURL, size: 36)
                            Text(initials(for: member.name))
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .frame(width: 40)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .background(Color.white)

            GroupMessagesListView(
                messages: viewModel.messages,
                currentUserId: viewModel.currentUserId
            )

            HStack(spacing: 8) {
                GrowingTextEditor(
                    text: $viewModel.inputText,
                    minHeight: 36,
                    maxHeight: 36 * 4
                )
                .font(.body)

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
                .opacity(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
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
        .sheet(isPresented: $showEditSheet) {
            EditGroupChatView(
                chatId: viewModel.chatId,
                currentMembers: viewModel.groupMembers,
                groupName: viewModel.groupName,
                isNewChat: false,
                currentUserId: viewModel.currentUserId,
                isCreator: viewModel.isCreator,
                onSave: { _, _ in
                    showEditSheet = false
                    viewModel.fetchGroupChat()
                },
                onCancel: {
                    showEditSheet = false
                },
                onDelete: {
                    showEditSheet = false
                    chatDeleted = true
                }
            )
        }
        .navigationBarHidden(true)
        .background(
            NavigationLink(
                destination: newChatDestination,
                isActive: $navigateToNewChat
            ) { EmptyView() }
            .hidden()
        )
        .onAppear { viewModel.activate() }
        .onChange(of: chatDeleted) { deleted in
            if deleted {
                viewModel.deactivate(reason: "chat_deleted")
                dismiss()
            }
        }
        .onDisappear {
            print("📤 GroupChatView onDisappear")
            viewModel.deactivate(reason: "onDisappear")
            
            // Post a notification to trigger an immediate, non-animated refresh
            NotificationCenter.default.post(name: .oneTimeRefreshActiveChats, object: nil)
        }
    }
}

struct EditGroupChatView: View {
    let chatId: Int?
    let currentMembers: [GroupMember]
    let groupName: String
    let isNewChat: Bool
    let currentUserId: Int
    let isCreator: Bool
    var onSave: (Int?, String?) -> Void
    var onCancel: () -> Void
    var onDelete: (() -> Void)? = nil

    @State private var editedName: String = ""
    @State private var selectedMembersToAdd: [Int: String] = [:]

    // Use separate sheet states instead of enum
    @State private var showAddMembersSheet = false
    @State private var showRemoveMembersSheet = false

    @State private var isLoading = false
    @State private var errorMessage: ErrorMessage?
    @State private var showDeleteAlert = false
    @AppStorage("jwtToken") var jwtToken: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                Form {
                    Section(header: Text("Group Name")) {
                        TextField("Group Name", text: $editedName)
                    }
                    Section(header: Text("Members")) {
                        let baseMembers = isNewChat ? [] : currentMembers
                        ForEach(baseMembers) { member in
                            HStack {
                                GroupMemberAvatar(name: member.name, photoURL: member.photoURL, size: 32)
                                Text(member.name)
                                Spacer()
                            }
                        }
                        let currentIds = Set(baseMembers.map { $0.id })
                        let pendingIds = Set(selectedMembersToAdd.keys).subtracting(currentIds)
                        ForEach(Array(pendingIds), id: \.self) { id in
                            // Wrap each row in a stable container
                            ZStack {
                                HStack {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                        .foregroundColor(.green)
                                    Text("Will add \(selectedMembersToAdd[id] ?? "User")")
                                        .foregroundColor(.green)
                                    Spacer()
                                }
                            }
                            .id("pending-\(id)")  // Existing stable ID
                            .transaction { t in
                                t.animation = nil  // Disable animations for this view
                            }
                        }
                        HStack {
                            Button {
                                showAddMembersSheet = true
                            } label: {
                                Label(isNewChat ? "Add Members" : "Add to Chat",
                                      systemImage: "person.crop.circle.badge.plus")
                            }
                            Spacer()
                            if !isNewChat {
                                Button {
                                    showRemoveMembersSheet = true
                                } label: {
                                    Label("Remove Member(s)", systemImage: "person.crop.circle.badge.minus")
                                        .foregroundColor(.red)
                                }
                                .disabled(currentMembers.count <= 1)
                            }
                        }
                    }

                    if !isNewChat && isCreator {
                        Section {
                            Button(role: .destructive) {
                                showDeleteAlert = true
                            } label: {
                                Label("Delete Group Chat", systemImage: "trash")
                            }
                        }
                    }
                }
                if isLoading {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView("Processing...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 10)
                }
            }
            .alert(item: $errorMessage) { msg in
                Alert(title: Text("Error"), message: Text(msg.message), dismissButton: .default(Text("OK")))
            }
            .alert("Delete Group Chat?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) { deleteGroupChat() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone.")
            }
            .navigationTitle(isNewChat ? "New Group Chat" : "Edit Group")
            .navigationBarItems(
                leading: Button("Cancel") { onCancel() },
                trailing: Button("Save") {
                    if isNewChat {
                        createGroupChat()
                    } else {
                        saveGroupChanges()
                    }
                }
            )
            .onAppear {
                if !isNewChat {
                    editedName = groupName
                }
            }
            // Use separate sheet modifiers instead of one enum-based sheet
            .sheet(isPresented: $showAddMembersSheet) {
                NTWKUserPicker(
                    onSelect: { selectedUsers in
                        for user in selectedUsers {
                            selectedMembersToAdd[user.id] = user.fullName ?? "User"
                        }
                    },
                    jwtToken: jwtToken,
                    chatId: chatId ?? 0,
                    alreadySelected: Set(selectedMembersToAdd.keys).union(currentMembers.map { $0.id }),
                    onCancel: { }
                )
            }
            .sheet(isPresented: $showRemoveMembersSheet) {
                RemoveMembersSheet(
                    members: currentMembers,
                    onRemove: { member in
                        removeMember(memberId: member.id)
                    },
                    onCancel: { }
                )
            }
        }
        .onChange(of: selectedMembersToAdd) { _ in
            // Force view stability when selection changes
            withAnimation(nil) {
                // This empty block disables animations during dictionary updates
            }
        }
    }

    private func createGroupChat() {
        isLoading = true
        errorMessage = nil
        guard let url = URL(string: "\(APIConfig.baseURL)/api/message/manage_chat") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        let allIds = [currentUserId] + Array(selectedMembersToAdd.keys)
        let body: [String: Any] = [
            "title": editedName, 
            "aAddIDs": allIds,
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = ErrorMessage(message: "Failed to create chat: \(error.localizedDescription)")
                    return
                }

                // Check for a valid HTTP response and status code
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    self.errorMessage = ErrorMessage(message: "Invalid server response. Status code: \(statusCode)")
                    return
                }

                guard let data = data, !data.isEmpty else {
                    self.errorMessage = ErrorMessage(message: "No data received from server.")
                    return
                }

                // The backend returns a dictionary with a 'chats_id' key.
                struct CreateChatResponse: Decodable {
                    let chats_id: Int
                }

                do {
                    let response = try JSONDecoder().decode(CreateChatResponse.self, from: data)
                    // Call the onSave closure with the new chat ID
                    self.onSave(response.chats_id, self.editedName)
                } catch {
                    self.errorMessage = ErrorMessage(message: "Error parsing server response: \(error.localizedDescription)")
                }
            }
        }.resume()
    }

    private func removeMember(memberId: Int) {
        isLoading = true
        errorMessage = nil
        guard let url = URL(string: "\(APIConfig.baseURL)/api/message/manage_chat") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        let body: [String: Any] = [
            "chats_id": chatId as Any,
            "aDelIDs": [memberId]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = ErrorMessage(message: error.localizedDescription)
                } else if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    errorMessage = ErrorMessage(message: "Failed to remove member. (\(http.statusCode))")
                } else {
                    onSave(nil, editedName)
                }
            }
        }.resume()
    }

    private func saveGroupChanges() {
        isLoading = true
        errorMessage = nil
        guard let url = URL(string: "\(APIConfig.baseURL)/api/message/manage_chat") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        let addIds = Array(Set(selectedMembersToAdd.keys).subtracting(currentMembers.map { $0.id }))
        let body: [String: Any] = [
            "chats_id": chatId as Any,
            "title": editedName,
            "aAddIDs": addIds
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = ErrorMessage(message: error.localizedDescription)
                } else if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    errorMessage = ErrorMessage(message: "Failed to save changes. (\(http.statusCode))")
                } else {
                    onSave(nil, editedName)
                }
            }
        }.resume()
    }

    private func deleteGroupChat() {
        guard let chatId = chatId else { return }
        isLoading = true
        errorMessage = nil
        guard let url = URL(string: "\(APIConfig.baseURL)/api/message/delete_chat") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        let body: [String: Any] = [
            "chats_id": chatId
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = ErrorMessage(message: error.localizedDescription)
                } else if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    errorMessage = ErrorMessage(message: "Failed to delete chat. (\(http.statusCode))")
                } else {
                    onDelete?()
                }
            }
        }.resume()
    }
}

// MARK: - Remove Members Sheet

struct RemoveMembersSheet: View {
    let members: [GroupMember]
    var onRemove: (GroupMember) -> Void
    var onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(members) { member in
                    Button(role: .destructive) {
                        onRemove(member)
                        dismiss()
                    } label: {
                        HStack {
                            GroupMemberAvatar(name: member.name, photoURL: member.photoURL, size: 32)
                            Text(member.name)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Remove Member(s)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - NTWKUserPicker (Add Members)

struct NTWKUserPicker: View {
    var onSelect: ([User]) -> Void
    var jwtToken: String
    var chatId: Int
    var alreadySelected: Set<Int> = []
    var onCancel: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var users: [User] = []
    @State private var isLoading = false
    @State private var errorMessage: ErrorMessage?
    @State private var selectedUsers: Set<Int> = []

    var body: some View {
        NavigationView {
            ZStack {
                List(users) { user in
                    Button {
                        if selectedUsers.contains(user.id) {
                            selectedUsers.remove(user.id)
                        } else {
                            selectedUsers.insert(user.id)
                        }
                    } label: {
                        HStack {
                            GroupMemberAvatar(name: user.fullName ?? "", photoURL: user.profilePictureURL, size: 32)
                            Text(user.fullName ?? "")
                            Spacer()
                            if selectedUsers.contains(user.id) || alreadySelected.contains(user.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .disabled(alreadySelected.contains(user.id))
                }
                if isLoading {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 10)
                }
            }
            .navigationTitle("Your NTWK")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel?()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        let selected = users.filter { selectedUsers.contains($0.id) }
                        onSelect(selected)
                        dismiss()
                    }
                    .disabled(selectedUsers.isEmpty)
                }
            }
            .onAppear { fetchNTWKUsers() }
            .alert(item: $errorMessage) { msg in
                Alert(title: Text("Error"), message: Text(msg.message), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func fetchNTWKUsers() {
        isLoading = true
        errorMessage = nil
        guard let url = URL(string: "\(APIConfig.baseURL)/api/user/members_of_my_network?not_in_chats_id=\(chatId)") else { return }
        var request = URLRequest(url: url)
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = ErrorMessage(message: error.localizedDescription)
                } else if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    errorMessage = ErrorMessage(message: "Failed to load NTWK. (\(http.statusCode))")
                } else if let data = data,
                          let decoded = try? JSONDecoder().decode([String: [User]].self, from: data),
                          let usersArr = decoded["result"] {
                    users = usersArr
                }
            }
        }.resume()
    }
}

// MARK: - Group Message Bubble

struct GroupMessageBubble: View {
    let message: GroupMessage
    let isCurrentUser: Bool

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
                VStack(alignment: .leading, spacing: 2) {
                    Text(message.senderName)
                        .font(.caption2)
                        .foregroundColor(.gray)
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

// MARK: - Optimistic Placeholder

fileprivate enum GroupMessagePlaceholder {
    static func make(id: Int, senderId: Int, text: String) -> GroupMessage {
        let iso = ISO8601DateFormatter().string(from: Date())
        let json: [String: Any] = [
            "id": id,
            "sender_id": senderId,
            "sender_name": "You",
            "sender_photo_url": NSNull(),
            "text": text,
            "timestamp": iso
        ]
        if let data = try? JSONSerialization.data(withJSONObject: json),
           let decoded = try? JSONDecoder().decode(GroupMessage.self, from: data) {
            return decoded
        }
        let data = try! JSONSerialization.data(withJSONObject: json)
        return try! JSONDecoder().decode(GroupMessage.self, from: data)
    }
}

// MARK: - Preview

struct GroupChatView_Previews: PreviewProvider {
    static var previews: some View {
        GroupChatView(
            viewModel: GroupChatViewModel(
                currentUserId: 1,
                chatId: 1,
                customChatTitle: "Goal Team: Example Goal"
            )
        )
    }
}
