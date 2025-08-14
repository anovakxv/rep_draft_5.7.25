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

// MARK: - ErrorMessage for Identifiable error alerts

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

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        senderId = try c.decode(Int.self, forKey: .senderId)
        senderName = (try? c.decode(String.self, forKey: .senderName)) ?? ""
        senderPhoto = try? c.decodeIfPresent(String.self, forKey: .senderPhoto)
        text = try c.decode(String.self, forKey: .text)
        let rawDate = (try? c.decodeIfPresent(String.self, forKey: .timestamp)) ??
                      (try? c.decodeIfPresent(String.self, forKey: .createdAt)) ?? ""
        if let parsed = ISO8601DateFormatter().date(from: rawDate) {
            timestamp = parsed
        } else {
            timestamp = Date()
        }
        print("[GroupMessage] senderName=\(senderName) rawPhoto=\(senderPhoto ?? "nil") finalURL=\(senderPhotoURL?.absoluteString ?? "nil")")
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
        print("[GroupMember] id=\(id) name=\(name) rawProfile=\(profilePicture ?? "nil") finalURL=\(photoURL?.absoluteString ?? "nil")")
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

    init(currentUserId: Int, chatId: Int, customChatTitle: String? = nil) {
        self.currentUserId = currentUserId
        self.chatId = chatId
        self.customChatTitle = customChatTitle
        print("[GroupChatVM:init] chatId=\(chatId) baseURL=\(APIConfig.baseURL)")
        if jwtToken.isEmpty {
            print("[GroupChatVM:init] jwtToken EMPTY")
        } else {
            print("[GroupChatVM:init] jwtToken len=\(jwtToken.count)")
        }
        fetchGroupChat()
        setupRealtime()
    }

    private func setupRealtime() {
        guard !jwtToken.isEmpty else { return }
        RealtimeSocketManager.shared.connect(baseURL: APIConfig.baseURL, token: jwtToken)
        RealtimeSocketManager.shared.onGroupMessage { [weak self] payload in
            guard let self = self else { return }
            print("[GroupChatVM \(self.chatId)] socket payload: \(payload)")
            guard let incomingChatId = payload["chat_id"] as? Int, incomingChatId == self.chatId else { return }
            if let data = try? JSONSerialization.data(withJSONObject: payload),
               let msg = try? JSONDecoder().decode(GroupMessage.self, from: data) {
                DispatchQueue.main.async {
                    if !self.messages.contains(where: { $0.id == msg.id }) {
                        // If optimistic placeholder exists (negative ID), replace it
                        if let idx = self.messages.firstIndex(where: { $0.id < 0 && $0.text == msg.text && $0.senderId == msg.senderId }) {
                            self.messages[idx] = msg
                        } else {
                            self.messages.append(msg)
                        }
                    }
                }
            }
        }
        RealtimeSocketManager.shared.join(chatId: chatId)
    }

    func fetchGroupChat() {
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
        print("[sendMessage] called with text: '\(trimmed)'")
        guard !trimmed.isEmpty else {
            print("[sendMessage] inputText is empty after trimming.")
            return
        }
        guard let url = URL(string: "\(APIConfig.baseURL)/api/message/send_chat_message") else {
            print("[sendMessage] Invalid URL")
            return
        }
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
        print("[sendMessage] Sending request: \(request) with body: \(body)")

        // Optimistic placeholder
        let tempId = -(messages.count + 1)
        let optimistic = GroupMessagePlaceholder.make(id: tempId, senderId: currentUserId, text: trimmed)
        DispatchQueue.main.async {
            self.messages.append(optimistic)
            self.inputText = ""
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[sendMessage] Network error: \(error)")
                return
            }
            if let http = response as? HTTPURLResponse {
                print("[sendMessage] HTTP status: \(http.statusCode)")
            }
            guard let data = data else {
                print("[sendMessage] No data returned")
                return
            }
            if let decoded = try? JSONDecoder().decode(SendGroupMessageAPIResponse.self, from: data) {
                let real = decoded.message
                DispatchQueue.main.async {
                    if let idx = self.messages.firstIndex(where: { $0.id == tempId }) {
                        self.messages[idx] = real
                    } else if !self.messages.contains(where: { $0.id == real.id }) {
                        self.messages.append(real)
                    }
                }
            } else {
                print("[sendMessage] Failed to decode response: \(String(data: data, encoding: .utf8) ?? "")")
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
    @StateObject var viewModel: GroupChatViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showEditSheet = false
    @State private var newChatId: Int? = nil
    @State private var navigateToNewChat = false

    // Custom init so callers can still pass a freshly created VM once.
    init(viewModel: GroupChatViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

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
        NavigationStack {
            VStack(spacing: 0) {
                GroupChatNavigationHeaderView(
                    name: viewModel.customChatTitle ?? viewModel.groupName,
                    onBack: { dismiss() },
                    onPlus: { showEditSheet = true }
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        let members = viewModel.groupMembers
                        ForEach(members) { member in
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

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                HStack(alignment: .bottom, spacing: 8) {
                                    if message.senderId == viewModel.currentUserId {
                                        Spacer()
                                        GroupMessageBubble(message: message, isCurrentUser: true)
                                    } else {
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
                        print("[UI] Send tapped. raw input='\(viewModel.inputText)' disabled? \(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)")
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
                    .background(Color.orange.opacity(0.2)) // TEMP: visualize hit area
                    // .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) // TEMP: allow always
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
                        showEditSheet = false
                        if let newChatId = newChatId {
                            RealtimeSocketManager.shared.join(chatId: newChatId)
                            self.newChatId = newChatId
                            self.navigateToNewChat = true
                        }
                    },
                    onCancel: {
                        showEditSheet = false
                    }
                )
            }
            .navigationBarHidden(true)
            .background(
                NavigationLink(
                    destination: newChatDestination,
                    isActive: $navigateToNewChat
                ) {
                    EmptyView()
                }
                .hidden()
            )
            .onAppear {
                print("[GroupChatView] onAppear chatId=\(viewModel.chatId)")
            }
        }
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
    var onSave: (Int?) -> Void
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
                } else if let data = data {
                    print("Create chat response: \(String(data: data, encoding: .utf8) ?? "")")
                    if let decoded = try? JSONDecoder().decode([String: AnyDecodable].self, from: data) {
                        if let chatDict = decoded["chat"]?.value as? [String: Any],
                           let chatId = chatDict["id"] as? Int {
                            onSave(chatId)
                        } else if let chatId = decoded["chats_id"]?.value as? Int {
                            onSave(chatId)
                        } else {
                            onSave(nil)
                        }
                    } else {
                        onSave(nil)
                    }
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
// Helper to build an optimistic GroupMessage
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
        // Fallback (should rarely happen)
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