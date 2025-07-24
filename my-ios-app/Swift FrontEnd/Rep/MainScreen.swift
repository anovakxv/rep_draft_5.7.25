//  Rep
//
//  Created by Dmytro Holovko on 02.12.2023.
//  Updated by Adam Novak on 06.19.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.

import SwiftUI
import Kingfisher

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
    let read: String?
}

// MARK: - ViewModels

class PortalsViewModel: ObservableObject {
    @Published var portals: [Portal] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchResults: [Portal] = []
    @Published var isSearching: Bool = false

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
        let limitParam = (tab == "all") ? "&limit=50" : ""
        let urlString = "\(APIConfig.baseURL)/api/portal/filter_network_portals?user_id=\(userId)&tab=\(tab)\(limitParam)"
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

    func searchPortals(query: String, limit: Int = 50) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            self.searchResults = []
            self.isSearching = false
            return
        }
        isLoading = true
        isSearching = true
        errorMessage = nil
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(APIConfig.baseURL)/api/search_portals?q=\(encodedQuery)&limit=\(limit)"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            isSearching = false
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
                    self.searchResults = []
                    self.isSearching = false
                    return
                }
                guard let data = data else {
                    self.errorMessage = "No data"
                    self.searchResults = []
                    self.isSearching = false
                    return
                }
                do {
                    let response = try JSONDecoder().decode(PortalsAPIResponse.self, from: data)
                    self.searchResults = response.result
                } catch {
                    self.errorMessage = "Failed to decode: \(error.localizedDescription)"
                    self.searchResults = []
                }
                self.isSearching = false
            }
        }.resume()
    }

    func clearSearch() {
        self.searchResults = []
        self.isSearching = false
    }
}

class PeopleViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var activeChats: [ActiveChat] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchResults: [User] = []
    @Published var isSearching: Bool = false

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
            let limitParam = (tab == "all") ? "&limit=50" : ""
            let urlString = "\(APIConfig.baseURL)/api/filter_people?user_id=\(userId)&tab=\(tab)\(limitParam)"
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

    func searchPeople(query: String, limit: Int = 50) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            self.searchResults = []
            self.isSearching = false
            return
        }
        isLoading = true
        isSearching = true
        errorMessage = nil
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(APIConfig.baseURL)/api/search_people?q=\(encodedQuery)&limit=\(limit)"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            isSearching = false
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
                    self.searchResults = []
                    self.isSearching = false
                    return
                }
                guard let data = data else {
                    self.errorMessage = "No data"
                    self.searchResults = []
                    self.isSearching = false
                    return
                }
                do {
                    let response = try JSONDecoder().decode(UsersAPIResponse.self, from: data)
                    self.searchResults = response.result
                } catch {
                    self.errorMessage = "Failed to decode: \(error.localizedDescription)"
                    self.searchResults = []
                }
                self.isSearching = false
            }
        }.resume()
    }

    func clearSearch() {
        self.searchResults = []
        self.isSearching = false
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
        static let imageSize: CGFloat = 28.0
    }
    enum MainActionSheetAction {
        case addPurpose
    }
}

struct MainScreen: View {
    @StateObject private var portalsVM = PortalsViewModel()
    @StateObject private var peopleVM = PeopleViewModel()
    @AppStorage("userId") var userId: Int = 0
    @AppStorage("jwtToken") var jwtToken: String = ""
    @State private var page: Page = .portals
    @State private var section = 2

    // Sheet and search state
    @State private var mainActiveSheet: MainScreenContent.ActiveSheet?
    @State private var showSearch = false
    @State private var searchText: String = ""
    @State private var searchDebounceTimer: Timer?
    @State private var pendingAction: MainActionSheetAction?
    @State private var currentUser: User? = nil

    var body: some View {
        NavigationStack {
            MainScreenContent(
                page: $page,
                section: $section,
                portalsVM: portalsVM,
                peopleVM: peopleVM,
                userId: userId,
                currentUser: currentUser,
                activeSheet: $mainActiveSheet,
                showSearch: $showSearch,
                searchText: $searchText,
                searchDebounceTimer: $searchDebounceTimer,
                pendingAction: $pendingAction,
                performSearch: performSearch,
                filteredUsers: filteredUsers,
                filteredActiveChats: filteredActiveChats,
                filteredPortals: filteredPortals,
                fetchCurrentUser: fetchCurrentUser
            )
            .modifier(MainScreenToolbar(
                section: $section,
                page: $page,
                portalsVM: portalsVM,
                peopleVM: peopleVM,
                userId: userId,
                currentUser: currentUser,
                showActionSheet: {
                    mainActiveSheet = .actionSheet
                }
            ))
            .toolbarBackground(Color(UIColor(red: 0.976, green: 0.976, blue: 0.976, alpha: 1.0)), for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            guard !jwtToken.isEmpty, userId != 0 else {
                // Optionally clear state here if needed
                return
            }
            if page == .portals {
                portalsVM.fetchPortals(userId: userId, section: section)
            } else {
                peopleVM.fetchPeople(userId: userId, section: section)
            }
            fetchCurrentUser()
        }
    }

    // --- Filtering logic for search ---
    private var filteredUsers: [User] {
        if showSearch && !searchText.isEmpty && section == 2 {
            return peopleVM.searchResults
        }
        if searchText.isEmpty { return peopleVM.users }
        return peopleVM.users.filter {
            ($0.fullName ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    private var filteredActiveChats: [ActiveChat] {
        if searchText.isEmpty { return peopleVM.activeChats }
        return peopleVM.activeChats.filter {
            ($0.user?.fullName ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    private var filteredPortals: [Portal] {
        if showSearch && !searchText.isEmpty && section == 2 {
            return portalsVM.searchResults
        }
        if searchText.isEmpty { return portalsVM.portals }
        return portalsVM.portals.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func performSearch(query: String) {
        if !showSearch || query.trimmingCharacters(in: .whitespaces).isEmpty {
            portalsVM.clearSearch()
            peopleVM.clearSearch()
            return
        }
        if page == .people && section == 2 {
            peopleVM.searchPeople(query: query)
        } else if page == .portals && section == 2 {
            portalsVM.searchPortals(query: query)
        }
    }

    private func fetchCurrentUser() {
        guard !jwtToken.isEmpty, userId != 0 else {
            DispatchQueue.main.async {
                self.currentUser = nil
            }
            return
        }
        guard let url = URL(string: "\(APIConfig.baseURL)/api/user/me") else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else { return }
            do {
                let decoded = try JSONDecoder().decode(UserProfileAPIResponse.self, from: data)
                DispatchQueue.main.async {
                    self.currentUser = decoded.result
                }
            } catch {
                // Ignore error, fallback to nil
                DispatchQueue.main.async {
                    self.currentUser = nil
                }
            }
        }.resume()
    }
}

// MARK: - MainScreenContent

extension MainScreenContent {
    enum ActiveSheet: Identifiable {
        case actionSheet
        case addPurpose

        var id: Int {
            switch self {
            case .actionSheet: return 1
            case .addPurpose: return 2
            }
        }
    }
}

struct MainScreenContent: View {
    @Binding var page: MainScreen.Page
    @Binding var section: Int
    @ObservedObject var portalsVM: PortalsViewModel
    @ObservedObject var peopleVM: PeopleViewModel
    var userId: Int
    var currentUser: User?
    @Binding var activeSheet: ActiveSheet?
    @Binding var showSearch: Bool
    @Binding var searchText: String
    @Binding var searchDebounceTimer: Timer?
    @Binding var pendingAction: MainScreen.MainActionSheetAction?
    var performSearch: (String) -> Void
    var filteredUsers: [User]
    var filteredActiveChats: [ActiveChat]
    var filteredPortals: [Portal]
    var fetchCurrentUser: () -> Void

    var body: some View {
        VStack(spacing: 0) {
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
                    if filteredActiveChats.isEmpty {
                        Text("No chats found.")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ActiveChatList(chats: filteredActiveChats)
                    }
                } else {
                    if filteredUsers.isEmpty {
                        Text("No people found.")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ChatList(users: filteredUsers)
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
                } else if filteredPortals.isEmpty {
                    Text("No portals found.")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    PortalList(portals: filteredPortals)
                }
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
                    searchText = ""
                    portalsVM.clearSearch()
                    peopleVM.clearSearch()
                },
                label: {
                    Image("REPLogo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40.0, height: 40.0)
                }
            )
            .padding(.trailing, 36)
            .padding(.bottom, 12)
        }
        .navigationBarBackButtonHidden()
        .overlay(
            Group {
                if showSearch {
                    VStack {
                        Spacer()
                        HStack {
                            TextField("Search...", text: $searchText)
                                .padding(10)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .padding(.horizontal)
                                .onChange(of: searchText) { newValue in
                                    searchDebounceTimer?.invalidate()
                                    searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { _ in
                                        performSearch(newValue)
                                    }
                                }
                            Button("Cancel") {
                                showSearch = false
                                searchText = ""
                                portalsVM.clearSearch()
                                peopleVM.clearSearch()
                            }
                            .padding(.trailing)
                        }
                        .padding(.bottom, 8)
                    }
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: showSearch)
                }
            }, alignment: .bottom
        )
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .actionSheet:
                VStack(spacing: 0) {
                    Button(action: {
                        pendingAction = .addPurpose
                        activeSheet = nil
                    }) {
                        Text("Add Purpose")
                            .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.vertical, 12)
                    }
                    Button(action: {
                        activeSheet = nil
                        showSearch = true
                    }) {
                        Text("Search")
                            .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.vertical, 12)
                    }
                    Button(action: { activeSheet = nil }) {
                        Text("Cancel")
                            .foregroundColor(.secondary)
                            .padding(.vertical, 12)
                    }
                }
                .padding()
                .presentationDetents([.medium])
            case .addPurpose:
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
                        aUsers: [],
                        aLeads: []
                    ),
                    userId: userId
                )
            }
        }
        .onChange(of: pendingAction) { action in
            guard let action = action else { return }
            switch action {
            case .addPurpose:
                activeSheet = .addPurpose
            }
            pendingAction = nil
        }
    }
}

// MARK: - MainScreenToolbar

struct MainScreenToolbar: ViewModifier {
    @Binding var section: Int
    @Binding var page: MainScreen.Page
    var portalsVM: PortalsViewModel
    var peopleVM: PeopleViewModel
    var userId: Int
    var currentUser: User?
    var showActionSheet: () -> Void

    func body(content: Content) -> some View {
        content
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
                        if let url = currentUser?.profilePictureURL {
                            KFImage(url)
                                .resizable()
                                .scaledToFill()
                                .frame(width: MainScreen.Constants.imageSize, height: MainScreen.Constants.imageSize)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle")
                                .resizable()
                                .frame(width: MainScreen.Constants.imageSize, height: MainScreen.Constants.imageSize)
                                .clipShape(Circle())
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(
                        action: { showActionSheet() },
                        label: {
                            Image(systemName: "plus")
                                .resizable()
                                .scaledToFit()
                                .frame(
                                    width: MainScreen.Constants.imageSize/1.5,
                                    height: MainScreen.Constants.imageSize/1.5
                                )
                                .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                        }
                    )
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
                                KFImage(url)
                                    .resizable()
                                    .scaledToFill()
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
                                        .font(.system(size: 17, weight: .semibold))
                                    Spacer()
                                    if let dateString = user.lastMessageDate, let date = ISO8601DateFormatter().date(from: dateString) {
                                        Text(date.timeAgoDisplay())
                                            .font(.caption)
                                    }
                                }
                                Text(user.lastMessage ?? "")
                                    .font(.system(size: 17))
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
                                    KFImage(url)
                                        .resizable()
                                        .scaledToFill()
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
                                            .font(.system(size: 17, weight: .semibold))
                                        Spacer()
                                        if let dateString = chat.last_message_time, let date = ISO8601DateFormatter().date(from: dateString) {
                                            Text(date.timeAgoDisplay())
                                                .font(.caption)
                                        }
                                    }
                                    if let lastMessage = chat.last_message,
                                       let read = lastMessage.read,
                                       read == "0",
                                       lastMessage.id != currentUserId {
                                        Text(lastMessage.text ?? "")
                                            .font(.system(size: 17, weight: .bold))
                                            .foregroundColor(Color.repGreen)
                                            .background(Color.white)
                                    } else {
                                        Text(chat.last_message?.text ?? "")
                                            .font(.system(size: 17))
                                            .foregroundColor(.primary)
                                    }
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