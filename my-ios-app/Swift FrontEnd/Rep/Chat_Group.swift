//  GroupChatView.swift
//  Rep
//
//  Created by Adam Novak on 06.19.2025
//  (c) 2025 Networked Capital Inc. All rights reserved.

import SwiftUI

// MARK: - Group Message Model

struct GroupMessage: Identifiable, Decodable {
    let id: Int
    let senderId: Int
    let senderName: String
    let senderPhotoURL: URL?
    let text: String
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case id
        case senderId = "sender_id"
        case senderName = "sender_name"
        case senderPhotoURL = "sender_photo_url"
        case text
        case timestamp
        case createdAt = "created_at" // fallback support
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        senderId = try c.decode(Int.self, forKey: .senderId)
        senderName = (try? c.decode(String.self, forKey: .senderName)) ?? ""
        if let urlStr = try? c.decodeIfPresent(String.self, forKey: .senderPhotoURL),
           let u = URL(string: urlStr) {
            senderPhotoURL = u
        } else {
            senderPhotoURL = nil
        }
        text = try c.decode(String.self, forKey: .text)
        let rawDate = (try? c.decodeIfPresent(String.self, forKey: .timestamp)) ??
                      (try? c.decodeIfPresent(String.self, forKey: .createdAt)) ?? ""
        if let parsed = ISO8601DateFormatter().date(from: rawDate) {
            timestamp = parsed
        } else {
            timestamp = Date()
        }
    }
}

// MARK: - Group Member Model

struct GroupMember: Identifiable, Decodable {
    let id: Int
    let name: String
    let photoURL: URL?

    enum CodingKeys: String, CodingKey {
        case id
        case name = "full_name"
        case photoURL = "profile_picture_url"
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

    let currentUserId: Int
    let chatId: Int
    let customChatTitle: String?

    @AppStorage("jwtToken") var jwtToken: String = ""

    private var realtimeInitialized = false

    init(currentUserId: Int, chatId: Int, customChatTitle: String? = nil) {
        self.currentUserId = currentUserId
        self.chatId = chatId
        self.customChatTitle = customChatTitle
        fetchGroupChat()
        setupRealtime()
    }

    private func setupRealtime() {
        guard !realtimeInitialized, !jwtToken.isEmpty else { return }
        realtimeInitialized = true
        // Connect & join room
        RealtimeSocketManager.shared.connect(baseURL: APIConfig.baseURL, token: jwtToken)
        RealtimeSocketManager.shared.onGroupMessage { [weak self] payload in
            guard let self = self else { return }
            // Validate chat
            guard let incomingChatId = payload["chat_id"] as? Int, incomingChatId == self.chatId else { return }
            // Decode
            if let data = try? JSONSerialization.data(withJSONObject: payload),
               let msg = try? JSONDecoder().decode(GroupMessage.self, from: data) {
                DispatchQueue.main.async {
                    if !self.messages.contains(where: { $0.id == msg.id }) {
                        self.messages.append(msg)
                    }
                }
            }
        }
        RealtimeSocketManager.shared.join(chatId: chatId)
    }

    func fetchGroupChat() {
        // UPDATED path to flattened group chat endpoint under /api/message
        guard let url = URL(string: "\(APIConfig.baseURL)/api/message/group_chat?chats_id=\(chatId)&limit=50") else { return }
        var request = URLRequest(url: url)
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else { return }
            if let apiResult = try? JSONDecoder().decode(GroupChatAPIResponse.self, from: data) {
                DispatchQueue.main.async {
                    self.groupName = apiResult.result.chat.name
                    self.groupMembers = apiResult.result.users
                    self.messages = apiResult.result.messages
                }
            }
        }.resume()
    }

    func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        // UPDATED path for send group message
        guard let url = URL(string: "\(APIConfig.baseURL)/api/message/send_chat_message") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "chats_id": chatId,
            "message": trimmed
        ])
        URLSession.shared.dataTask(with: request) { _, _, _ in }.resume()
        // Clear immediately; socket broadcast will append
        DispatchQueue.main.async { self.inputText = "" }
    }

    deinit {
        RealtimeSocketManager.shared.leave(chatId: chatId)
    }
}

// MARK: - Custom Navigation Header

struct GroupChatNavigationHeaderView:  View {
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

// MARK: - Group Chat View

struct GroupChatView: View {
    @ObservedObject var viewModel: GroupChatViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showEditSheet = false

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
                        VStack(spacing: 2) {
                            if let url = member.photoURL {
                                AsyncImage(url: url) { image in
                                    image.resizable().aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Circle().fill(Color.gray.opacity(0.3))
                                }
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 36, height: 36)
                            }
                            Text(member.name)
                                .font(.caption2)
                                .lineLimit(1)
                                .frame(width: 40)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .background(Color.white)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            HStack(alignment: .bottom, spacing: 8) {
                                if message.senderId == viewModel.currentUserId {
                                    Spacer()
                                    GroupMessageBubble(message: message, isCurrentUser: true)
                                } else {
                                    if let url = message.senderPhotoURL {
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
                                    GroupMessageBubble(message: message, isCurrentUser: false)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                }
                .background(Color.white)
                .onChange(of: viewModel.messages.count) { _ in
                    if let last = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

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
                onSave: {
                    viewModel.fetchGroupChat()
                    showEditSheet = false
                },
                onCancel: {
                    showEditSheet = false
                }
            )
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Edit Group Chat Sheet
struct EditGroupChatView: View {
    let chatId: Int
    let currentMembers: [GroupMember]
    let groupName: String
    var onSave: () -> Void
    var onCancel: () -> Void

    @State private var editedName: String = ""
    @State private var selectedMemberIds: Set<Int> = []
    @State private var showAddSheet = false
    @State private var showRemoveSheet = false
    @State private var ntwkUsers: [User] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @AppStorage("jwtToken") var jwtToken: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                Form {
                    Section(header: Text("Group Name")) {
                        TextField("Group Name", text: $editedName)
                    }
                    Section(header: Text("Members")) {
                        ForEach(currentMembers) { member in
                            HStack {
                                if let url = member.photoURL {
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
                                Text(member.name)
                                Spacer()
                            }
                        }
                        HStack {
                            Button(action: { showAddSheet = true }) {
                                Label("Add to Chat", systemImage: "person.crop.circle.badge.plus")
                            }
                            Spacer()
                            Button(action: { showRemoveSheet = true }) {
                                Label("Remove Member", systemImage: "person.crop.circle.badge.minus")
                                    .foregroundColor(.red)
                            }
                            .disabled(currentMembers.count <= 1)
                        }
                    }
                }
                if isLoading {
                    Color.black.opacity(0.2)
                        .edgesIgnoringSafeArea(.all)
                    ProgressView("Processing...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 10)
                }
            }
            .alert(item: $errorMessage) { msg in
                Alert(title: Text("Error"), message: Text(msg), dismissButton: .default(Text("OK")))
            }
            .navigationTitle("Edit Group")
            .navigationBarItems(
                leading: Button("Cancel") { onCancel() },
                trailing: Button("Save") {
                    saveGroupChanges()
                }
            )
            .onAppear {
                editedName = groupName
            }
            .sheet(isPresented: $showAddSheet) {
                NTWKUserPicker(
                    onSelect: { user in
                        selectedMemberIds.insert(user.id)
                        showAddSheet = false
                    },
                    jwtToken: jwtToken,
                    chatId: chatId
                )
            }
            .actionSheet(isPresented: $showRemoveSheet) {
                ActionSheet(
                    title: Text("Remove Group Member"),
                    message: Text("Select members to remove from this group chat."),
                    buttons: removeMemberButtons() + [.cancel()]
                )
            }
        }
    }

    private func removeMemberButtons() -> [ActionSheet.Button] {
        currentMembers.map { member in
            .destructive(Text(member.name)) {
                removeMember(memberId: member.id)
            }
        }
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
            "chats_id": chatId,
            "aDelIDs": [memberId]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = error.localizedDescription
                } else if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    errorMessage = "Failed to remove member. (\(http.statusCode))"
                } else {
                    onSave()
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
        let addIds = Array(selectedMemberIds.subtracting(currentMembers.map { $0.id }))
        let body: [String: Any] = [
            "chats_id": chatId,
            "title": editedName,
            "aAddIDs": addIds
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = error.localizedDescription
                } else if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    errorMessage = "Failed to save changes. (\(http.statusCode))"
                } else {
                    onSave()
                }
            }
        }.resume()
    }
}

// Helper struct for picking NTWK users
struct NTWKUserPicker: View {
    var onSelect: (User) -> Void
    var jwtToken: String
    var chatId: Int

    @Environment(\.dismiss) private var dismiss
    @State private var users: [User] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ZStack {
                List(users) { user in
                    Button(action: { onSelect(user) }) {
                        HStack {
                            if let url = user.profilePictureURL {
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
                            Text(user.fullName ?? "")
                        }
                    }
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
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { fetchNTWKUsers() }
            .alert(item: $errorMessage) { msg in
                Alert(title: Text("Error"), message: Text(msg), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func fetchNTWKUsers() {
        isLoading = true
        errorMessage = nil
        guard let url = URL(string: "\(APIConfig.baseURL)/api/members_of_my_network?not_in_chats_id=\(chatId)") else { return }
        var request = URLRequest(url: url)
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = error.localizedDescription
                } else if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    errorMessage = "Failed to load NTWK. (\(http.statusCode))"
                } else if let data = data,
                          let decoded = try? JSONDecoder().decode(NTWKUsersAPIResponse.self, from: data) {
                    users = decoded.result
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
        VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 2) {
            if !isCurrentUser {
                Text(message.senderName)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            Text(message.text)
                .padding(10)
                .background(isCurrentUser ? Color.repGreen : Color(UIColor.systemGray5))
                .foregroundColor(isCurrentUser ? .white : .black)
                .cornerRadius(16)
            Text(message.timestamp, style: .time)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: 260, alignment: isCurrentUser ? .trailing : .leading)
        .id(message.id)
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