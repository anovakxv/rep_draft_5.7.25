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
            value = ()
        }
    }
}

// MARK: - ErrorMessage for Identifiable error alerts

struct ErrorMessage: Identifiable {
    let id = UUID()
    let message: String
}

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
            
            // --- Horizontal member list (profile pics + names) ---
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    let members = viewModel.groupMembers
                    ForEach(members) { member in
                        VStack {
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
            // --- End horizontal member list ---

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
                chatId: nil,
                currentMembers: [],
                groupName: "",
                isNewChat: true,
                currentUserId: viewModel.currentUserId,
                onSave: { newChatId in
                    // Navigate to GroupChatView with newChatId
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

enum EditGroupSheetType: Identifiable {
    case add
    case remove

    var id: Int {
        switch self {
        case .add: return 1
        case .remove: return 2
        }
    }
}

struct EditGroupChatView: View {
    let chatId: Int?
    let currentMembers: [GroupMember]
    let groupName: String
    let isNewChat: Bool
    let currentUserId: Int
    var onSave: (Int?) -> Void // Passes new chatId if created, else nil
    var onCancel: () -> Void

    @State private var editedName: String = ""
    @State private var selectedMembersToAdd: [Int: String] = [:]
    @State private var activeSheet: EditGroupSheetType?
    @State private var isLoading = false
    @State private var errorMessage: ErrorMessage?
    @AppStorage("jwtToken") var jwtToken: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                Form {
                    Section(header: Text("Group Name")) {
                        TextField("Group Name", text: $editedName)
                    }
                    Section(header: Text("Members")) {
                        // Show current or selected members
                        let baseMembers = isNewChat ? [] : currentMembers
                        ForEach(baseMembers) { member in
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
                        // Show pending additions by name
                        let currentIds = Set(baseMembers.map { $0.id })
                        let pendingIds = Set(selectedMembersToAdd.keys).subtracting(currentIds)
                        ForEach(Array(pendingIds), id: \.self) { id in
                            HStack {
                                Image(systemName: "person.crop.circle.badge.plus")
                                    .foregroundColor(.green)
                                Text("Will add \(selectedMembersToAdd[id] ?? "User")")
                                    .foregroundColor(.green)
                                Spacer()
                            }
                        }
                        HStack {
                            Button(action: { activeSheet = .add }) {
                                Label(isNewChat ? "Add Members" : "Add to Chat", systemImage: "person.crop.circle.badge.plus")
                            }
                            Spacer()
                            if !isNewChat {
                                Button(action: { activeSheet = .remove }) {
                                    Label("Remove Member(s)", systemImage: "person.crop.circle.badge.minus")
                                        .foregroundColor(.red)
                                }
                                .disabled(currentMembers.count <= 1)
                            }
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
                Alert(title: Text("Error"), message: Text(msg.message), dismissButton: .default(Text("OK")))
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
                editedName = groupName
            }
            .sheet(item: $activeSheet) { sheetType in
                switch sheetType {
                case .add:
                    NTWKUserPicker(
                        onSelect: { selectedUsers in
                            for user in selectedUsers {
                                selectedMembersToAdd[user.id] = user.fullName ?? "User"
                            }
                            activeSheet = nil
                        },
                        jwtToken: jwtToken,
                        chatId: chatId ?? 0,
                        alreadySelected: Set(selectedMembersToAdd.keys).union(currentMembers.map { $0.id })
                    )
                case .remove:
                    RemoveMembersSheet(
                        members: currentMembers,
                        onRemove: { member in
                            activeSheet = nil
                            removeMember(memberId: member.id)
                        },
                        onCancel: {
                            activeSheet = nil
                        }
                    )
                }
            }
        }
    }

    // --- New Chat Creation Logic ---
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
        // Always include self
        let allIds = [currentUserId] + Array(selectedMembersToAdd.keys)
        let body: [String: Any] = [
            "title": editedName,
            "aAddIDs": allIds
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = ErrorMessage(message: error.localizedDescription)
                } else if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    errorMessage = ErrorMessage(message: "Failed to create chat. (\(http.statusCode))")
                } else if let data = data,
                          let decoded = try? JSONDecoder().decode([String: AnyDecodable].self, from: data),
                          let chatId = (decoded["result"]?.value as? [String: Any])?["id"] as? Int {
                    onSave(chatId)
                } else {
                    onSave(nil)
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
            "chats_id": chatId,
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
                    onSave(nil)
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
            "chats_id": chatId,
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
                    onSave(nil)
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

// Helper struct for picking NTWK users (multi-select)
struct NTWKUserPicker: View {
    var onSelect: ([User]) -> Void
    var jwtToken: String
    var chatId: Int
    var alreadySelected: Set<Int> = []

    @Environment(\.dismiss) private var dismiss
    @State private var users: [User] = []
    @State private var isLoading = false
    @State private var errorMessage: ErrorMessage?
    @State private var selectedUsers: Set<Int> = []

    var body: some View {
        NavigationView {
            ZStack {
                List(users) { user in
                    Button(action: {
                        if selectedUsers.contains(user.id) {
                            selectedUsers.remove(user.id)
                        } else {
                            selectedUsers.insert(user.id)
                        }
                    }) {
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
                    Button("Cancel") { dismiss() }
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