//  MainScreen.swift
//  Rep
//
//  Created by Dmytro Holovko on 02.12.2023.
//  Updated by Adam Novak on 06.19.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.

import SwiftUI

// MARK: - API Responses

struct UsersAPIResponse: Decodable {
    let result: [User]
}

struct ActiveChatAPIResponse: Decodable {
    let result: [ActiveChat]
}

struct ActiveChat: Identifiable, Decodable {
    let id: String // "direct-<userId>" or "group-<chatId>"
    let type: String // "direct" or "group"
    let user: User?
    let chat: ChatModel?
    let last_message: MessageModel?
    let last_message_time: String?
}

struct ChatModel: Decodable {
    let id: Int
    let name: String?
}

struct MessageModel: Decodable {
    let id: Int
    let text: String?
    let created_at: String?
}

// MARK: - ViewModels

class PortalsViewModel: ObservableObject {
    @Published var portals: [Portal] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    @AppStorage("jwtToken") var jwtToken: String = ""

    func fetchPortals(userId: Int, section: Int) {
        isLoading = true
        errorMessage = nil
        let tab: String
        switch section {
        case 0: tab = "open"
        case 1: tab = "ntwk"
        case 2: tab = "all"
        default: tab = "open"
        }
        // Updated API URL root to match Flask blueprint registration
        let urlString = "\(APIConfig.baseURL)/api/portal/filter_network_portals?user_id=\(userId)&tab=\(tab)"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        var request = URLRequest(url: url)
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.portals = []
                    return
                }
                guard let data = data else {
                    self.errorMessage = "No data"
                    self.portals = []
                    return
                }
                do {
                    let response = try JSONDecoder().decode([String: [Portal]].self, from: data)
                    self.portals = response["result"] ?? []
                } catch {
                    self.errorMessage = "Failed to decode: \(error.localizedDescription)"
                    self.portals = []
                }
            }
        }.resume()
    }
}

class PeopleViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var activeChats: [ActiveChat] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    @AppStorage("jwtToken") var jwtToken: String = ""

    func fetchPeople(userId: Int, section: Int) {
        isLoading = true
        errorMessage = nil

        if section == 0 {
            let urlString = "\(APIConfig.baseURL)/api/active_chat_list?user_id=\(userId)"
            guard let url = URL(string: urlString) else {
                errorMessage = "Invalid URL"
                isLoading = false
                return
            }
            var request = URLRequest(url: url)
            if !jwtToken.isEmpty {
                request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
            }
            URLSession.shared.dataTask(with: request) { data, _, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        self.activeChats = []
                        return
                    }
                    guard let data = data else {
                        self.errorMessage = "No data"
                        self.activeChats = []
                        return
                    }
                    do {
                        let response = try JSONDecoder().decode(ActiveChatAPIResponse.self, from: data)
                        self.activeChats = response.result
                    } catch {
                        self.errorMessage = "Failed to decode: \(error.localizedDescription)"
                        self.activeChats = []
                    }
                }
            }.resume()
        } else {
            let tab = section == 1 ? "ntwk" : "all"
            let urlString = "\(APIConfig.baseURL)/api/filter_people?user_id=\(userId)&tab=\(tab)"
            guard let url = URL(string: urlString) else {
                errorMessage = "Invalid URL"
                isLoading = false
                return
            }
            var request = URLRequest(url: url)
            if !jwtToken.isEmpty {
                request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
            }
            URLSession.shared.dataTask(with: request) { data, _, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        self.users = []
                        return
                    }
                    guard let data = data else {
                        self.errorMessage = "No data"
                        self.users = []
                        return
                    }
                    do {
                        let response = try JSONDecoder().decode(UsersAPIResponse.self, from: data)
                        self.users = response.result
                    } catch {
                        self.errorMessage = "Failed to decode: \(error.localizedDescription)"
                        self.users = []
                    }
                }
            }.resume()
        }
    }
}

// MARK: - MainSegmentedPicker

struct MainSegmentedPicker: View {
    let segments: [String]
    @Binding var selectedIndex: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(segments.indices, id: \.self) { index in
                Button(action: {
                    selectedIndex = index
                }) {
                    ZStack {
                        (selectedIndex == index ? Color.black : Color.white)
                        Text(segments[index])
                            .fontWeight(.medium)
                            .foregroundColor(selectedIndex == index ? .white : .black)
                            .frame(maxWidth: .infinity, minHeight: 32)
                            .padding(.vertical, 2)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .frame(maxWidth: .infinity)
                .overlay(
                    Rectangle()
                        .frame(width: index < segments.count - 1 ? 1 : 0)
                        .foregroundColor(Color(UIColor(red: 0.894, green: 0.894, blue: 0.894, alpha: 1.0))),
                    alignment: .trailing
                )
            }
        }
        .frame(width: 240, height: 32)
        .background(Color(UIColor(red: 0.976, green: 0.976, blue: 0.976, alpha: 1.0)))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.black, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - MainScreen

extension MainScreen {
    enum Page {
        case portals
        case people
    }
    enum Constants {
        static let imageSize: CGFloat = 24.0
    }
    enum MainActionSheetAction {
        case addPurpose
        case editProfile
        case newChat
    }
}

struct MainScreen: View {
    @StateObject private var portalsVM = PortalsViewModel()
    @StateObject private var peopleVM = PeopleViewModel()
    @AppStorage("userId") var userId: Int = 0
    @State private var page: Page = .portals
    @State private var section = 2

    // Action Sheet State
    @State private var showActionSheet = false
    @State private var pendingAction: MainActionSheetAction?
    @State private var showEditProfile = false
    @State private var showAddPurpose = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Main content
                switch page {
                case .people:
                    if peopleVM.isLoading {
                        ProgressView("Loading people...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = peopleVM.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if section == 0 {
                        if peopleVM.activeChats.isEmpty {
                            Text("No chats found.")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            ActiveChatList(chats: peopleVM.activeChats)
                        }
                    } else {
                        if peopleVM.users.isEmpty {
                            Text("No people found.")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            ChatList(users: peopleVM.users)
                        }
                    }
                case .portals:
                    if portalsVM.isLoading {
                        ProgressView("Loading portals...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = portalsVM.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if portalsVM.portals.isEmpty {
                        Text("No portals found.")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        PortalList(portals: portalsVM.portals)
                    }
                }
            }
            .toolbarBackground(Color(UIColor(red: 0.976, green: 0.976, blue: 0.976, alpha: 1.0)), for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    MainSegmentedPicker(
                        segments: ["OPEN", "NTWK", "ALL"],
                        selectedIndex: $section
                    )
                    .onChange(of: section) { newSection in
                        if page == .portals {
                            portalsVM.fetchPortals(userId: userId, section: newSection)
                        } else {
                            peopleVM.fetchPeople(userId: userId, section: newSection)
                        }
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(destination: ProfileView(userId: userId)) {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .frame(width: Constants.imageSize, height: Constants.imageSize)
                            .clipShape(Circle())
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(
                        action: { showActionSheet = true },
                        label: {
                            Image(systemName: "plus")
                                .resizable()
                                .scaledToFit()
                                .frame(
                                    width: Constants.imageSize/1.5,
                                    height: Constants.imageSize/1.5
                                )
                                .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                        }
                    )
                }
            }
            .overlay(alignment: .bottomTrailing) {
                Button(
                    action: {
                        page = page == .people ? .portals : .people
                        if page == .portals {
                            portalsVM.fetchPortals(userId: userId, section: section)
                        } else {
                            peopleVM.fetchPeople(userId: userId, section: section)
                        }
                    },
                    label: {
                        Image("REPLogo")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 36.0, height: 36.0)
                    }
                )
                .padding(.trailing, 36)
                .padding(.bottom, 12)
            }
            .navigationBarBackButtonHidden()
        }
        .sheet(isPresented: $showActionSheet) {
            VStack(spacing: 0) {
                Button(action: {
                    pendingAction = .addPurpose
                    showActionSheet = false
                }) {
                    Text("Add Purpose")
                        .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.vertical, 12)
                }
                Button(action: {
                    pendingAction = .editProfile
                    showActionSheet = false
                }) {
                    Text("Edit Profile")
                        .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.vertical, 12)
                }
                Button(action: {
                    pendingAction = .newChat
                    showActionSheet = false
                }) {
                    Text("New Chat")
                        .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.vertical, 12)
                }
                Button(action: { showActionSheet = false }) {
                    Text("Cancel")
                        .foregroundColor(.secondary)
                        .padding(.vertical, 12)
                }
            }
            .padding()
            .presentationDetents([.medium])
        }
        .onChange(of: pendingAction) { action in
            guard let action = action else { return }
            switch action {
            case .addPurpose:
                showAddPurpose = true
            case .editProfile:
                showEditProfile = true
            case .newChat:
                // TODO: Present Group Chat page
                break
            }
            pendingAction = nil
        }
        .sheet(isPresented: $showAddPurpose) {
            EditPortalView(
                portal: PortalDetail(
                    id: 0,
                    name: "",
                    subtitle: "",
                    about: "",
                    categories_id: nil,
                    cities_id: nil,
                    lead_id: nil,
                    users_id: userId,
                    _c_users_count: nil,
                    mainImageUrl: nil,
                    aGoals: [],
                    aPortalUsers: [],
                    aTexts: [],
                    aSections: [],
                    aUsers: []
                ),
                userId: userId
            )
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(
                viewModel: ProfileInfoViewModel(
                    profileInfo: ProfileInfo(
                        firstName: "",
                        lastName: "",
                        skills: [],
                        type: .lead,
                        cityName: "",
                        image: nil,
                        about: "",
                        broadcast: "",
                        otherSkill: ""
                    ),
                    mode: .edit
                )
            )
        }
        .onAppear {
            if page == .portals {
                portalsVM.fetchPortals(userId: userId, section: section)
            } else {
                peopleVM.fetchPeople(userId: userId, section: section)
            }
        }
    }
}

// MARK: - Portal List

struct PortalList: View {
    var portals: [Portal]
    @AppStorage("userId") var userId: Int = 0

    var body: some View {
        List {
            ForEach(portals) { portal in
                VStack {
                    NavigationLink {
                        PortalPage(portalId: portal.id, userId: userId)
                    } label: {
                        PortalItem(portal: portal)
                    }
                    Divider()
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Chat List

struct ChatList: View {
    var users: [User]
    @State private var selectedProfileId: Int?
    @State private var selectedChatId: Int?
    @AppStorage("userId") var currentUserId: Int = 0

    var body: some View {
        ZStack {
            List {
                ForEach(users) { user in
                    HStack(spacing: 0) {
                        Button(action: { selectedProfileId = user.id }) {
                            if let url = user.profilePictureURL {
                                AsyncImage(url: url) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Color.gray
                                }
                                .frame(width: 64, height: 64)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.crop.circle")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 64, height: 64)
                                    .clipShape(Circle())
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.leading, 16)
                        Button(action: { selectedChatId = user.id }) {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(user.fullName ?? "")
                                        .font(.subheadline)
                                    Spacer()
                                    if let dateString = user.lastMessageDate, let date = ISO8601DateFormatter().date(from: dateString) {
                                        Text(date.timeAgoDisplay())
                                            .font(.caption)
                                    }
                                }
                                Text(user.lastMessage ?? "")
                                    .font(.caption)
                            }
                            .padding(.leading, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .frame(height: 64)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .listRowInsets(EdgeInsets())
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color(UIColor(red: 0.894, green: 0.894, blue: 0.894, alpha: 1.0))),
                        alignment: .bottom
                    )
                }
            }
            .listStyle(.plain)

            // NavigationLinks for programmatic navigation
            NavigationLink(
                destination: selectedProfileId.map { ProfileView(userId: $0) },
                isActive: Binding(
                    get: { selectedProfileId != nil },
                    set: { if !$0 { selectedProfileId = nil } }
                ),
                label: { EmptyView() }
            )
            NavigationLink(
                destination: selectedChatId.flatMap { id in
                    if let user = users.first(where: { $0.id == id }) {
                        Chat(
                            userId: user.id,
                            userName: user.fullName ?? "",
                            userPhotoURL: user.profilePictureURL
                        )
                    } else {
                        Chat(userId: id)
                    }
                },
                isActive: Binding(
                    get: { selectedChatId != nil },
                    set: { if !$0 { selectedChatId = nil } }
                ),
                label: { EmptyView() }
            )
        }
    }
}

// MARK: - Active Chat List

struct ActiveChatList: View {
    var chats: [ActiveChat]
    @State private var selectedProfileId: Int?
    @State private var selectedChatId: Int?
    @AppStorage("userId") var currentUserId: Int = 0

    var body: some View {
        ZStack {
            List {
                ForEach(chats) { chat in
                    if chat.type == "direct", let user = chat.user {
                        HStack(spacing: 0) {
                            Button(action: { selectedProfileId = user.id }) {
                                if let url = user.profilePictureURL {
                                    AsyncImage(url: url) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        Color.gray
                                    }
                                    .frame(width: 64, height: 64)
                                    .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.crop.circle")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 64, height: 64)
                                        .clipShape(Circle())
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.leading, 16)
                            Button(action: { selectedChatId = user.id }) {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(user.fullName ?? "")
                                            .font(.subheadline)
                                        Spacer()
                                        if let dateString = chat.last_message_time, let date = ISO8601DateFormatter().date(from: dateString) {
                                            Text(date.timeAgoDisplay())
                                                .font(.caption)
                                        }
                                    }
                                    Text(chat.last_message?.text ?? "")
                                        .font(.caption)
                                }
                                .padding(.leading, 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .frame(height: 64)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .listRowInsets(EdgeInsets())
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color(UIColor(red: 0.894, green: 0.894, blue: 0.894, alpha: 1.0))),
                            alignment: .bottom
                        )
                    } else if chat.type == "group", let group = chat.chat {
                        Button(action: { selectedChatId = group.id }) {
                            HStack(spacing: 0) {
                                Image(systemName: "person.3.fill")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 64, height: 64)
                                    .clipShape(Circle())
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(group.name ?? "Group Chat")
                                            .font(.subheadline)
                                        Spacer()
                                        if let dateString = chat.last_message_time, let date = ISO8601DateFormatter().date(from: dateString) {
                                            Text(date.timeAgoDisplay())
                                                .font(.caption)
                                        }
                                    }
                                    Text(chat.last_message?.text ?? "")
                                        .font(.caption)
                                }
                                .padding(.leading, 8)
                            }
                            .frame(height: 64)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .listRowInsets(EdgeInsets())
                            .overlay(
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(Color(UIColor(red: 0.894, green: 0.894, blue: 0.894, alpha: 1.0))),
                                alignment: .bottom
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .listStyle(.plain)

            NavigationLink(
                destination: selectedProfileId.map { ProfileView(userId: $0) },
                isActive: Binding(
                    get: { selectedProfileId != nil },
                    set: { if !$0 { selectedProfileId = nil } }
                ),
                label: { EmptyView() }
            )
            NavigationLink(
                destination: selectedChatId.flatMap { id in
                    if let chat = chats.first(where: { $0.user?.id == id }) {
                        Chat(
                            userId: id,
                            userName: chat.user?.fullName ?? "",
                            userPhotoURL: chat.user?.profilePictureURL
                        )
                    } else {
                        Chat(userId: id)
                    }
                },
                isActive: Binding(
                    get: { selectedChatId != nil },
                    set: { if !$0 { selectedChatId = nil } }
                ),
                label: { EmptyView() }
            )
        }
    }
}

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - Chat Page

struct Chat: View {
    let userId: Int
    var userName: String = ""
    var userPhotoURL: URL? = nil
    @AppStorage("userId") var currentUserId: Int = 0

    var body: some View {
        MessageView(
            viewModel: MessageViewModel(
                currentUserId: currentUserId,
                otherUserId: userId,
                otherUserName: userName,
                otherUserPhotoURL: userPhotoURL
            )
        )
    }
}