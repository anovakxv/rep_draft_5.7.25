//  Rep
//
//  Created by Dmytro Holovko on 02.12.2023.
//  Updated by Adam Novak on 06.19.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights

import SwiftUI
import Kingfisher

// MARK: - API Responses

struct UsersAPIResponse: Decodable {
    let result: [User]
}

struct ActiveChatAPIResponse: Decodable {
    let result: [ActiveChat]
}

struct ActiveChat: Identifiable, Decodable, Equatable {
    let id: String          // "direct-<userId>" or "group-<chatId>"
    let type: String        // "direct" or "group"
    let user: User?
    let chat: ChatModel?
    let last_message: MessageModel?
    let last_message_time: String?

    static func == (lhs: ActiveChat, rhs: ActiveChat) -> Bool {
        lhs.id == rhs.id &&
        lhs.type == rhs.type &&
        lhs.last_message?.id == rhs.last_message?.id &&
        lhs.last_message_time == rhs.last_message_time
    }
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
    let sender_id: Int?
}

// MARK: - ViewModels

class PortalsViewModel: ObservableObject {
    @Published var portals: [Portal] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchResults: [Portal] = []
    @Published var isSearching: Bool = false
    @Published private var backgroundPortalsTab0: [Portal] = []
    @Published private var backgroundPortalsTab1: [Portal] = []
    @Published private var backgroundPortalsTab2: [Portal] = []
    private var isInitialFetch = true

    @AppStorage("jwtToken") var jwtToken: String = ""

    func fetchPortals(userId: Int, section: Int, safeOnly: Bool = false, isTabSwitch: Bool = false) {
        if !isTabSwitch {
            isLoading = true
        }
        errorMessage = nil
        let tab: String
        switch section {
        case 0: tab = "open"
        case 1: tab = "ntwk"
        case 2: tab = "all"
        default: tab = "open"
        }
        let limitParam = (tab == "all") ? "&limit=200" : ""
        let safeParam = safeOnly ? "&safe_only=true" : ""
        let urlString = "\(APIConfig.baseURL)/api/portal/filter_network_portals?user_id=\(userId)&tab=\(tab)\(limitParam)\(safeParam)"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        var request = URLRequest(url: url)
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let http = response as? HTTPURLResponse {
                    if http.statusCode == 401 || http.statusCode == 403 {
                        self.errorMessage = "Session expired. Please log in again."
                        self.portals = []
                        AuthSession.handleUnauthorized("PortalsViewModel.fetchPortals")
                        return
                    }
                    if http.statusCode < 200 || http.statusCode >= 300 {
                        self.errorMessage = "Server error (\(http.statusCode))."
                        self.portals = []
                        return
                    }
                }
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
                    if isTabSwitch {
                        withAnimation(nil) {
                            self.portals = response["result"] ?? []
                        }
                    } else {
                        self.portals = response["result"] ?? []
                    }
                } catch {
                    self.errorMessage = "Failed to decode."
                    self.portals = []
                }
            }
        }.resume()
    }

    func searchPortals(query: String, limit: Int = 50) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            isSearching = false
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
        searchResults = []
        isSearching = false
    }
    func getBackgroundPortals(for section: Int) -> [Portal] {
        switch section {
        case 0: return backgroundPortalsTab0
        case 1: return backgroundPortalsTab1
        case 2: return backgroundPortalsTab2
        default: return []
        }
    }

    func loadBackgroundData(from section: Int, to targetSection: Int, userId: Int, safeOnly: Bool) {
        // Don't overwrite current tab
        if section == targetSection { return }
        
        let tab: String
        switch targetSection {
        case 0: tab = "open"
        case 1: tab = "ntwk"
        case 2: tab = "all"
        default: tab = "open"
        }
        
        let limitParam = (tab == "all") ? "&limit=200" : ""
        let safeParam = safeOnly ? "&safe_only=true" : ""
        let urlString = "\(APIConfig.baseURL)/api/portal/filter_network_portals?user_id=\(userId)&tab=\(tab)\(limitParam)\(safeParam)"
        
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { print("Background fetch error: \(error.localizedDescription)"); return }
            guard let data = data else { return }
            
            do {
                let response = try JSONDecoder().decode([String: [Portal]].self, from: data)
                DispatchQueue.main.async {
                    let result = response["result"] ?? []
                    switch targetSection {
                    case 0: self.backgroundPortalsTab0 = result
                    case 1: self.backgroundPortalsTab1 = result
                    case 2: self.backgroundPortalsTab2 = result
                    default: break
                    }
                }
            } catch {
                print("Background decode error: \(error.localizedDescription)")
            }
        }.resume()
    }
}

class PeopleViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var activeChats: [ActiveChat] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchResults: [User] = []
    @Published var isSearching: Bool = false
    @Published var skipNextAnimations: Bool = false
    @Published private var backgroundUsersTab1: [User] = []
    @Published private var backgroundUsersTab2: [User] = []
    @Published private var backgroundActiveChats: [ActiveChat] = []

    private var fetchThrottleTimer: Timer?
    private var lastFetchTime: TimeInterval = 0
    private var isFetching = false

    private var activeRefreshTask: Task<Void, Never>?
    private var lastRefreshRequestTime: Date = .distantPast
    private let minimumRefreshInterval: TimeInterval = 0.25

    @Published var hasUnreadDirectMessages: Bool = false {
        didSet {
            if oldValue != hasUnreadDirectMessages {
                UserDefaults.standard.set(hasUnreadDirectMessages, forKey: "hasUnreadDMFlag")
            }
        }
    }
    @Published var hasUnreadGroupMessages: Bool = false {
        didSet {
            if oldValue != hasUnreadGroupMessages {
                UserDefaults.standard.set(hasUnreadGroupMessages, forKey: "hasUnreadGroupFlag")
            }
        }
    }

    @AppStorage("jwtToken") var jwtToken: String = ""

    func fetchPeople(userId: Int, section: Int, force: Bool = false, isTabSwitch: Bool = false) {
        // Cancel any previous refresh task
        activeRefreshTask?.cancel()

        // For section 0 (active chats), implement strict refresh control
        if section == 0 {
            let now = Date()
            let timeSinceLastRequest = now.timeIntervalSince(lastRefreshRequestTime)

            // If we've refreshed very recently and this isn't a manual tab switch or forced, skip it
            if timeSinceLastRequest < minimumRefreshInterval && !force && !isTabSwitch {
                print("⏱️ Skipping refresh - too soon (interval: \(timeSinceLastRequest)s)")
                return
            }

            // Update the timestamp for this request
            lastRefreshRequestTime = now

            // Create a new task that will handle the refresh
            activeRefreshTask = Task {
                // If task was cancelled, exit
                if Task.isCancelled {
                    print("❌ Refresh task cancelled")
                    return
                }

                // Perform the actual fetch on the main thread
                await MainActor.run {
                    performActiveChatsFetch(userId: userId, force: force)
                }
            }
            return
        }

        // For other sections, use the existing logic
        if isFetching && !force {
            return
        }

        // Update timestamp for notification handlers
        lastFetchTime = Date().timeIntervalSince1970
        performPeopleFetch(userId: userId, section: section)
    }

    func cancelPendingRefreshes(section: Int) {
        // Only cancel if conflicting with current section
        if section == 0 && activeRefreshTask != nil {
            activeRefreshTask?.cancel()
        }
        fetchThrottleTimer?.invalidate()
        fetchThrottleTimer = nil
    }

    func searchPeople(query: String, limit: Int = 50) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            isSearching = false
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
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let http = response as? HTTPURLResponse {
                    if http.statusCode == 401 || http.statusCode == 403 {
                        self.errorMessage = "Session expired. Please log in again."
                        self.searchResults = []
                        self.isSearching = false
                        AuthSession.handleUnauthorized("PeopleViewModel.searchPeople")
                        return
                    }
                    if http.statusCode < 200 || http.statusCode >= 300 {
                        self.errorMessage = "Server error (\(http.statusCode))."
                        self.searchResults = []
                        self.isSearching = false
                        return
                    }
                }
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
                    self.errorMessage = "Failed to decode."
                    self.searchResults = []
                }
                self.isSearching = false
            }
        }.resume()
    }

    func clearSearch() {
        searchResults = []
        isSearching = false
    }

    func getBackgroundData(for section: Int) -> [User] {
        if section == 0 { return [] } // Active chats use different data structure
        return section == 1 ? backgroundUsersTab1 : backgroundUsersTab2
    }

    func getBackgroundActiveChats() -> [ActiveChat] {
        return backgroundActiveChats
    }

    func loadBackgroundData(from section: Int, to targetSection: Int, userId: Int) {
        // Don't overwrite current tab
        if section == targetSection { return }
        
        if targetSection == 0 {
            // Load active chats in background
            let urlString = "\(APIConfig.baseURL)/api/active_chat_list?user_id=\(userId)"
            guard let url = URL(string: urlString) else { return }
            var request = URLRequest(url: url)
            if !jwtToken.isEmpty {
                request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
            }
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error { print("Background fetch error: \(error.localizedDescription)"); return }
                guard let data = data else { return }
                
                do {
                    let response = try JSONDecoder().decode(ActiveChatAPIResponse.self, from: data)
                    DispatchQueue.main.async {
                        self.backgroundActiveChats = response.result
                    }
                } catch {
                    print("Background decode error: \(error.localizedDescription)")
                }
            }.resume()
        } else {
            // Load users in background
            let tab = targetSection == 1 ? "ntwk" : "all"
            let limitParam = (tab == "all") ? "&limit=200" : ""
            let urlString = "\(APIConfig.baseURL)/api/filter_people?user_id=\(userId)&tab=\(tab)\(limitParam)"
            guard let url = URL(string: urlString) else { return }
            var request = URLRequest(url: url)
            if !jwtToken.isEmpty {
                request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
            }
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error { print("Background fetch error: \(error.localizedDescription)"); return }
                guard let data = data else { return }
                
                do {
                    let response = try JSONDecoder().decode(UsersAPIResponse.self, from: data)
                    DispatchQueue.main.async {
                        if targetSection == 1 {
                            self.backgroundUsersTab1 = response.result
                        } else {
                            self.backgroundUsersTab2 = response.result
                        }
                    }
                } catch {
                    print("Background decode error: \(error.localizedDescription)")
                }
            }.resume()
        }
    }

    private func performActiveChatsFetch(userId: Int, force: Bool) {
        // Prevent concurrent fetches
        if isFetching && !force {
            return
        }
        
        isFetching = true
        if !skipNextAnimations {
            isLoading = true
        }
        errorMessage = nil
        
        // Active chats fetch code
        let urlString = "\(APIConfig.baseURL)/api/active_chat_list?user_id=\(userId)"
        guard let url = URL(string: urlString) else {
            self.errorMessage = "Invalid URL"
            self.isLoading = false
            self.isFetching = false
            return
        }
        
        var request = URLRequest(url: url)
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                self.isFetching = false
                if let http = response as? HTTPURLResponse {
                    if http.statusCode == 401 || http.statusCode == 403 {
                        self.errorMessage = "Session expired. Please log in again."
                        self.activeChats = []
                        AuthSession.handleUnauthorized("PeopleViewModel.fetchPeople.active_chats")
                        return
                    }
                    if http.statusCode < 200 || http.statusCode >= 300 {
                        self.errorMessage = "Server error (\(http.statusCode))."
                        self.activeChats = []
                        return
                    }
                }
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
                    if self.skipNextAnimations {
                        withAnimation(nil) {
                            self.activeChats = response.result
                        }
                        self.skipNextAnimations = false
                    } else {
                        self.activeChats = response.result
                    }
                    // Only count unread if last message is from someone else
                    let hasUnreadDM = response.result.contains {
                        $0.type == "direct"
                        && (($0.last_message?.read ?? "0") == "0")
                        && (($0.last_message?.sender_id ?? -1) != userId)
                    }
                    let hasUnreadGroup = response.result.contains {
                        $0.type == "group"
                        && (($0.last_message?.read ?? "0") == "0")
                        && (($0.last_message?.sender_id ?? -1) != userId)
                    }
                    self.hasUnreadDirectMessages = hasUnreadDM
                    self.hasUnreadGroupMessages = hasUnreadGroup
                } catch {
                    self.errorMessage = "Failed to decode."
                    self.activeChats = []
                }
            }
        }.resume()
    }

    // New helper method for people list fetches
    private func performPeopleFetch(userId: Int, section: Int) {
        isFetching = true
        isLoading = true
        errorMessage = nil
        
        // People list fetch code
        let tab = section == 1 ? "ntwk" : "all"
        let limitParam = (tab == "all") ? "&limit=200" : ""
        let urlString = "\(APIConfig.baseURL)/api/filter_people?user_id=\(userId)&tab=\(tab)\(limitParam)"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            isFetching = false
            return
        }
        
        var request = URLRequest(url: url)
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                self.isFetching = false
                if let http = response as? HTTPURLResponse {
                    if http.statusCode == 401 || http.statusCode == 403 {
                        self.errorMessage = "Session expired. Please log in again."
                        self.users = []
                        AuthSession.handleUnauthorized("PeopleViewModel.fetchPeople.people_list")
                        return
                    }
                    if http.statusCode < 200 || http.statusCode >= 300 {
                        self.errorMessage = "Server error (\(http.statusCode))."
                        self.users = []
                        return
                    }
                }
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
                    self.errorMessage = "Failed to decode."
                    self.users = []
                }
            }
        }.resume()
    }
}

// MARK: - MainSegmentedPicker

struct MainSegmentedPicker: View {
    let segments: [String]
    @Binding var selectedIndex: Int
    var attentionDotIndices: Set<Int> = []
    var onSelect: ((Int) -> Void)? = nil

    var body: some View {
        HStack(spacing: 0) {
            ForEach(segments.indices, id: \.self) { index in
                Button(action: {
                    if let onSelect { onSelect(index) } else { selectedIndex = index }
                }) {
                    ZStack(alignment: .topLeading) {
                        (selectedIndex == index ? Color.black : Color.white)
                        Text(segments[index])
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(selectedIndex == index ? .white : .black)
                            .frame(maxWidth: .infinity, minHeight: 32)
                            .padding(.vertical, 2)

                        if index == 0 && attentionDotIndices.contains(0) {
                            Circle()
                                .fill(Color.repGreen)
                                .frame(width: 12, height: 12)
                                .padding(.top, 4)
                                .padding(.leading, 4)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .contentShape(Rectangle())
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
        .animation(.easeInOut(duration: 0.15), value: attentionDotIndices)
        .frame(width: 220, height: 32)
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
        case teamChat
    }
}

struct MainScreen: View {
    @StateObject private var portalsVM = PortalsViewModel()
    @StateObject private var peopleVM = PeopleViewModel()
    @AppStorage("userId") var userId: Int = 0
    @AppStorage("jwtToken") var jwtToken: String = ""
    @AppStorage("hasUnreadDMFlag") private var persistedUnreadDM: Bool = false
    @AppStorage("hasUnreadGroupFlag") private var persistedUnreadGroup: Bool = false

    @State private var page: Page = .portals
    @State private var section = 2

    @State private var newGroupChatId: Int? = nil
    @State private var navigateToGroupChat = false
    @State private var showCreateGroupChatSheet = false
    @State private var lastRefreshTime: TimeInterval = 0

    @State private var mainActiveSheet: MainScreenContent.ActiveSheet?
    @State private var showSearch = false
    @State private var searchText: String = ""
    @State private var searchDebounceTimer: Timer?
    @State private var pendingAction: MainActionSheetAction?
    @State private var currentUser: User? = nil
    @State private var showOnlySafePortals = false

    @State private var inviteCheckTimer: Timer?
    @ObservedObject private var invitesManager = GoalTeamInvitesManager.shared
    @State private var openNeedsAttention: Bool = false

    @State private var initialUnreadPollScheduled = false
    @State private var notifObserversInstalled = false
    @State private var socketHandlersInstalled = false
    
    // Break up the complex view into smaller properties
    private var mainContent: some View {
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
                fetchCurrentUser: fetchCurrentUser,
                showOnlySafePortals: $showOnlySafePortals
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
                },
                openNeedsAttention: $openNeedsAttention,
                forceShowPeopleOpen: forceShowPeopleOpen,
                showOnlySafePortals: showOnlySafePortals
            ))
            .toolbarBackground(Color(UIColor(red: 0.976, green: 0.976, blue: 0.976, alpha: 1.0)), for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $navigateToGroupChat) {
                if let chatId = newGroupChatId {
                    GroupChatView(
                        viewModel: GroupChatViewModel(
                            currentUserId: userId,
                            chatId: chatId
                        )
                    )
                } else {
                    EmptyView()
                }
            }
        }
    }
    
    private var createGroupChatSheet: some View {
        EditGroupChatView(
            chatId: nil,
            currentMembers: [],
            groupName: "",
            isNewChat: true,
            currentUserId: userId,
            isCreator: true,
            onSave: { newChatId, chatName in  // Add chatName parameter
                showCreateGroupChatSheet = false
                guard let newChatId = newChatId else { return }

                // Optimistically add to the list with the correct name
                let newOptimisticChat = ActiveChat(
                    id: "group-\(newChatId)",
                    type: "group",
                    user: nil,
                    chat: ChatModel(id: newChatId, name: chatName ?? "New Chat"),  // Use provided name
                    last_message: nil,
                    last_message_time: ISO8601DateFormatter().string(from: Date())
                )
                if !peopleVM.activeChats.contains(where: { $0.id == newOptimisticChat.id }) {
                    peopleVM.activeChats.insert(newOptimisticChat, at: 0)
                }

                // Set the ID and trigger navigation
                DispatchQueue.main.async {
                    self.newGroupChatId = newChatId
                    self.navigateToGroupChat = true
                }
            },
            onCancel: {
                showCreateGroupChatSheet = false
            }
        )
    }

    var body: some View {
        ZStack {
            mainContent
        }
        .onAppear {
            if persistedUnreadDM {
                peopleVM.hasUnreadDirectMessages = true
                if userId != 0 && !jwtToken.isEmpty {
                    peopleVM.fetchPeople(userId: userId, section: 0, isTabSwitch: true)
                }
            }
            if persistedUnreadGroup {
                peopleVM.hasUnreadGroupMessages = true
                if userId != 0 && !jwtToken.isEmpty {
                    peopleVM.fetchPeople(userId: userId, section: 0, isTabSwitch: true)
                }
            }
            guard !jwtToken.isEmpty, userId != 0 else { return }
            if section == 0 {
                // Always load chats for section 0
                peopleVM.fetchPeople(userId: userId, section: 0, isTabSwitch: true)
            } else if page == .portals {
                portalsVM.fetchPortals(userId: userId, section: section, safeOnly: showOnlySafePortals)
            } else {
                peopleVM.fetchPeople(userId: userId, section: section, isTabSwitch: true)
            }
            fetchCurrentUser()
            setupSocketNotifications()
            installSocketInviteObservers()
            // Invite polling: quick one-shot at 1s, then every 30s (unchanged)
            inviteCheckTimer?.invalidate()
            inviteCheckTimer = nil
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                GoalTeamInvitesManager.shared.fetchPendingInvites()
            }
            inviteCheckTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
                GoalTeamInvitesManager.shared.fetchPendingInvites()
            }
            recalcOpenNeedsAttention()
            scheduleUnreadPollingIfNeeded()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // Start background loading the other tabs
                if page == .portals {
                    portalsVM.loadBackgroundData(from: section, to: (section + 1) % 3, userId: userId, safeOnly: showOnlySafePortals)
                    portalsVM.loadBackgroundData(from: section, to: (section + 2) % 3, userId: userId, safeOnly: showOnlySafePortals)
                } else {
                    peopleVM.loadBackgroundData(from: section, to: (section + 1) % 3, userId: userId)
                    peopleVM.loadBackgroundData(from: section, to: (section + 2) % 3, userId: userId)
                }
            }
        }
        .onDisappear {
            inviteCheckTimer?.invalidate()
            inviteCheckTimer = nil
        }
        .onChange(of: showOnlySafePortals) { newValue in
            if page == .portals {
                portalsVM.fetchPortals(userId: userId, section: section, safeOnly: newValue)
            }
        }
        .onChange(of: section) { newSection in
            if newSection == 0 {
                // Always load chats when section 0 is selected
                let backgroundChats = peopleVM.getBackgroundActiveChats()
                if !backgroundChats.isEmpty {
                    peopleVM.activeChats = backgroundChats
                }
                peopleVM.fetchPeople(userId: userId, section: 0, isTabSwitch: true)

                // Start loading the other sections in the background
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    peopleVM.loadBackgroundData(from: newSection, to: (newSection + 1) % 3, userId: userId)
                    peopleVM.loadBackgroundData(from: newSection, to: (newSection + 2) % 3, userId: userId)
                }
            } else if page == .portals {
                // Existing portal logic for sections 1 & 2
                let backgroundData = portalsVM.getBackgroundPortals(for: newSection)
                if !backgroundData.isEmpty {
                    portalsVM.portals = backgroundData
                }

                portalsVM.fetchPortals(userId: userId, section: newSection, safeOnly: showOnlySafePortals, isTabSwitch: true)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    portalsVM.loadBackgroundData(from: newSection, to: (newSection + 1) % 3, userId: userId, safeOnly: showOnlySafePortals)
                    portalsVM.loadBackgroundData(from: newSection, to: (newSection + 2) % 3, userId: userId, safeOnly: showOnlySafePortals)
                }
            } else {
                // Existing people logic for sections 1 & 2
                let backgroundUsers = peopleVM.getBackgroundData(for: newSection)
                if !backgroundUsers.isEmpty {
                    peopleVM.users = backgroundUsers
                }

                peopleVM.fetchPeople(userId: userId, section: newSection, isTabSwitch: true)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    peopleVM.loadBackgroundData(from: newSection, to: (newSection + 1) % 3, userId: userId)
                    peopleVM.loadBackgroundData(from: newSection, to: (newSection + 2) % 3, userId: userId)
                }
            }
        }
        .onChange(of: page) { newPage in
            scheduleUnreadPollingIfNeeded()

            // Don't reload data if we're on Chats tab - it doesn't change with page toggle
            if section == 0 {
                return
            }

            if newPage == .portals {
                print("🔄 Refreshing portals after tab switch")
                
                // If we have background data for this section, use it first
                let backgroundData = portalsVM.getBackgroundPortals(for: section)
                if !backgroundData.isEmpty {
                    // Instantly show background data
                    portalsVM.portals = backgroundData
                }
                
                // Then refresh to get the latest data
                portalsVM.fetchPortals(userId: userId, section: section, safeOnly: showOnlySafePortals, isTabSwitch: true)
                
                // Start preloading data for other tabs
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    portalsVM.loadBackgroundData(from: section, to: (section + 1) % 3, userId: userId, safeOnly: showOnlySafePortals)
                    portalsVM.loadBackgroundData(from: section, to: (section + 2) % 3, userId: userId, safeOnly: showOnlySafePortals)
                }
            } else {
                // People page, similar logic
                if section == 0 {
                    let backgroundChats = peopleVM.getBackgroundActiveChats()
                    if !backgroundChats.isEmpty {
                        peopleVM.activeChats = backgroundChats
                    }
                } else {
                    let backgroundUsers = peopleVM.getBackgroundData(for: section)
                    if !backgroundUsers.isEmpty {
                        peopleVM.users = backgroundUsers
                    }
                }
                
                peopleVM.fetchPeople(userId: userId, section: section, isTabSwitch: true)
                
                // Start preloading data for other tabs
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    peopleVM.loadBackgroundData(from: section, to: (section + 1) % 3, userId: userId)
                    peopleVM.loadBackgroundData(from: section, to: (section + 2) % 3, userId: userId)
                }
            }
        }
        .onChange(of: pendingAction) { action in
            guard let action = action else { return }
            switch action {
            case .addPurpose:
                mainActiveSheet = .addPurpose
            case .teamChat:
                showCreateGroupChatSheet = true
            }
            pendingAction = nil
        }
        .onChange(of: peopleVM.activeChats) { _ in
            recalcOpenNeedsAttention()
        }
        .onChange(of: invitesManager.pendingInvites) { _ in
            recalcOpenNeedsAttention()
        }
        .onChange(of: peopleVM.hasUnreadDirectMessages) { _ in
            recalcOpenNeedsAttention()
        }
        .onChange(of: peopleVM.hasUnreadGroupMessages) { _ in
            recalcOpenNeedsAttention()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            setupSocketNotifications()
            installSocketInviteObservers()
            scheduleUnreadPollingIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("refreshActiveChats"))) { _ in
            // Add debounce to prevent rapid reloading
            let currentTime = Date().timeIntervalSince1970
            if currentTime - self.lastRefreshTime > 0.75 {
                self.lastRefreshTime = currentTime
                peopleVM.fetchPeople(userId: userId, section: 0, force: true)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("oneTimeRefreshActiveChats"))) { _ in
            print("🔄 Processing one-time refresh (gentle version)")
            
            // Block any subsequent refreshes for a short period
            self.lastRefreshTime = Date().timeIntervalSince1970 + 2.0
            
            // Cancel any pending refresh tasks
            peopleVM.cancelPendingRefreshes(section: section)
            
            // Schedule a single refresh with animation suppression
            peopleVM.skipNextAnimations = true
            peopleVM.fetchPeople(userId: userId, section: 0, force: true)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("cancelPendingRefreshes"))) { _ in
            peopleVM.cancelPendingRefreshes(section: section)
        }
        .sheet(isPresented: $showCreateGroupChatSheet) {
            createGroupChatSheet
        }
    }

    // MARK: - Socket Notification Setup
    private func setupSocketNotifications() {
        guard !jwtToken.isEmpty, userId != 0 else { return }

        RealtimeSocketManager.shared.connect(
            baseURL: APIConfig.baseURL,
            token: jwtToken,
            userId: userId
        )

        guard !socketHandlersInstalled else { return }
        socketHandlersInstalled = true

        func toInt(_ any: Any?) -> Int? {
            if let v = any as? Int { return v }
            if let v = any as? NSNumber { return v.intValue }
            if let s = any as? String, let v = Int(s) { return v }
            return nil
        }

        RealtimeSocketManager.shared.onDirectMessageNotification { payload in
            // Accept common keys and multiple types
            let senderAny    = payload["sender_id"] ?? payload["senderId"]
            let recipientAny = payload["recipient_id"] ?? payload["recipientId"]
            let senderId     = toInt(senderAny) ?? -1
            let recipientId  = toInt(recipientAny) ?? -1

            // Defensive checks, but don't block if parsing failed; prefer showing the dot
            if senderId == self.userId { return }
            if recipientId != self.userId && recipientId != -1 { return }

            DispatchQueue.main.async {
                // Instant UI feedback
                self.peopleVM.hasUnreadDirectMessages = true
                // Reconcile after brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.peopleVM.fetchPeople(userId: self.userId, section: 0, force: true)
                }
            }
        }

        RealtimeSocketManager.shared.onGroupMessage { payload in
            let senderAny = payload["sender_id"] ?? payload["senderId"]
            let senderId  = (senderAny as? Int) ?? (senderAny as? NSNumber)?.intValue ?? Int((senderAny as? String) ?? "") ?? -1
            if senderId == self.userId { return }
            DispatchQueue.main.async {
                self.peopleVM.hasUnreadGroupMessages = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.peopleVM.fetchPeople(userId: self.userId, section: 0, force: true)
                }
            }
        }

        RealtimeSocketManager.shared.onGroupMessageNotification { payload in
            let senderAny = payload["sender_id"] ?? payload["senderId"]
            let senderId  = (senderAny as? Int) ?? (senderAny as? NSNumber)?.intValue ?? Int((senderAny as? String) ?? "") ?? -1
            if senderId == self.userId { return }
            DispatchQueue.main.async {
                self.peopleVM.hasUnreadGroupMessages = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.peopleVM.fetchPeople(userId: self.userId, section: 0, force: true)
                }
            }
        }
    }

    // MARK: - Install Socket Invite Observers
    private func installSocketInviteObservers() {
        guard !notifObserversInstalled else { return }
        notifObserversInstalled = true
        NotificationCenter.default.addObserver(forName: .socketGoalTeamInvite, object: nil, queue: .main) { _ in
            // Instant UI feedback for invites
            self.openNeedsAttention = true
            GoalTeamInvitesManager.shared.fetchPendingInvites()
        }
        NotificationCenter.default.addObserver(forName: .socketGoalTeamInviteUpdate, object: nil, queue: .main) { _ in
            // Keep it simple: flip dot on; fetch will reconcile state
            self.openNeedsAttention = true
            GoalTeamInvitesManager.shared.fetchPendingInvites()
        }
    }

    // MARK: - Filtering
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
            if $0.type == "direct" {
                return ($0.user?.fullName ?? "").localizedCaseInsensitiveContains(searchText)
            } else {
                return ($0.chat?.name ?? "").localizedCaseInsensitiveContains(searchText)
            }
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

    // MARK: - State / Helpers
    private func recalcOpenNeedsAttention() {
        // Include DM + Group + persisted + invites
        let currentUnread = peopleVM.hasUnreadDirectMessages
            || peopleVM.hasUnreadGroupMessages
            || persistedUnreadDM
            || persistedUnreadGroup
        let newValue = currentUnread || !invitesManager.pendingInvites.isEmpty
        if newValue != openNeedsAttention {
            withAnimation { openNeedsAttention = newValue }
        } else {
            openNeedsAttention = newValue
        }
        // Persist DM
        if !peopleVM.hasUnreadDirectMessages && persistedUnreadDM {
            persistedUnreadDM = false
        } else if peopleVM.hasUnreadDirectMessages && !persistedUnreadDM {
            persistedUnreadDM = true
        }
        // Persist Group
        if !peopleVM.hasUnreadGroupMessages && persistedUnreadGroup {
            persistedUnreadGroup = false
        } else if peopleVM.hasUnreadGroupMessages && !persistedUnreadGroup {
            persistedUnreadGroup = true
        }
    }

    private func forceShowPeopleOpen() {
        page = .people
        if section != 0 {
            section = 0
        } else {
            peopleVM.fetchPeople(userId: userId, section: 0, isTabSwitch: true)
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
            DispatchQueue.main.async { self.currentUser = nil }
            return
        }
        guard let url = URL(string: "\(APIConfig.baseURL)/api/user/me") else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, _ in
            if let http = response as? HTTPURLResponse {
                if http.statusCode == 401 || http.statusCode == 403 {
                    AuthSession.handleUnauthorized("MainScreen.fetchCurrentUser")
                    return
                }
                if http.statusCode < 200 || http.statusCode >= 300 {
                    DispatchQueue.main.async { self.currentUser = nil }
                    return
                }
            }
            guard let data = data else { return }
            do {
                let decoded = try JSONDecoder().decode(UserProfileAPIResponse.self, from: data)
                DispatchQueue.main.async { self.currentUser = decoded.result }
            } catch {
                DispatchQueue.main.async { self.currentUser = nil }
            }
        }.resume()
    }

    // MARK: - One-shot unread fallback (first open only)
    private func scheduleUnreadPollingIfNeeded() {
        guard !initialUnreadPollScheduled else { return }
        guard page == .portals,
              !peopleVM.hasUnreadDirectMessages,
              !peopleVM.hasUnreadGroupMessages else { return }

        initialUnreadPollScheduled = true
        Timer.scheduledTimer(withTimeInterval: 1.75, repeats: false) { _ in
            if self.page == .portals
                && !self.peopleVM.hasUnreadDirectMessages
                && !self.peopleVM.hasUnreadGroupMessages {
                print("🕑 One-shot unread poll (1s)")
                self.peopleVM.fetchPeople(userId: self.userId, section: 0, force: true)
            }
        }
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

// MARK: - ChatsList Component

struct ChatsList: View {
    @ObservedObject var peopleVM: PeopleViewModel
    var filteredActiveChats: [ActiveChat]
    @ObservedObject var invitesManager: GoalTeamInvitesManager

    var body: some View {
        Group {
            if peopleVM.isLoading {
                ProgressView("Loading chats...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = peopleVM.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredActiveChats.isEmpty && invitesManager.pendingInvites.isEmpty {
                Text("No chats found.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ActiveChatList(
                    chats: filteredActiveChats,
                    invitesManager: invitesManager
                )
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
    @Binding var showOnlySafePortals: Bool

    @ObservedObject private var invitesManager = GoalTeamInvitesManager.shared

    // Break up complex views into separate computed properties
    var peopleContent: some View {
        Group {
            if peopleVM.isLoading {
                ProgressView("Loading people...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = peopleVM.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if section == 0 {
                if filteredActiveChats.isEmpty && invitesManager.pendingInvites.isEmpty {
                    Text("No chats found.")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ActiveChatList(
                        chats: filteredActiveChats,
                        invitesManager: invitesManager
                    )
                }
            } else {
                if filteredUsers.isEmpty {
                    Text(section == 1 ? "No members of your network yet. View a profile and +NTWK to build your network!" : "No people found.")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ChatList(users: filteredUsers)
                }
            }
        }
    }
    var portalsContent: some View {
        Group {
            if portalsVM.isLoading {
                ProgressView("Loading portals...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = portalsVM.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredPortals.isEmpty {
                Text(section == 1 ? "No members of your network yet. View a profile and +NTWK to build your network!" : "No portals found.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                PortalList(portals: filteredPortals)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if section == 0 {
                // Always show chats for section 0, regardless of page
                ChatsList(
                    peopleVM: peopleVM,
                    filteredActiveChats: filteredActiveChats,
                    invitesManager: invitesManager
                )
            } else {
                // For sections 1 & 2, keep the toggle between people/portals
                switch page {
                case .people:
                    peopleContent
                case .portals:
                    portalsContent
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Button(
                action: {
                    page = page == .people ? .portals : .people
                    if section != 0 {  // Only fetch if not on Chats tab
                        if page == .portals {
                            portalsVM.fetchPortals(userId: userId, section: section, safeOnly: showOnlySafePortals)
                        } else {
                            peopleVM.fetchPeople(userId: userId, section: section)
                        }
                    }
                    searchText = ""
                    portalsVM.clearSearch()
                    peopleVM.clearSearch()
                },
                label: {
                    Image("REPLogo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44.0, height: 44.0)
                        .contentShape(Rectangle())
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
                VStack(spacing: 24) {
                    HStack(spacing: 24) {
                        Text("Show:")
                            .font(.body)
                            .fontWeight(.regular)
                            .foregroundColor(.secondary)
                            .padding(.trailing, 4)
                        Button(action: {
                            showOnlySafePortals = false
                            portalsVM.fetchPortals(userId: userId, section: section, safeOnly: false)
                        }) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .stroke(Color.secondary, lineWidth: 2)
                                        .frame(width: 20, height: 20)
                                    if !showOnlySafePortals {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                            .font(.system(size: 14, weight: .bold))
                                    }
                                }
                                Text("All")
                                    .font(.body)
                                    .fontWeight(!showOnlySafePortals ? .bold : .regular)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        Button(action: {
                            showOnlySafePortals = true
                            portalsVM.fetchPortals(userId: userId, section: section, safeOnly: true)
                        }) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .stroke(Color.secondary, lineWidth: 2)
                                        .frame(width: 20, height: 20)
                                    if showOnlySafePortals {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                            .font(.system(size: 14, weight: .bold))
                                    }
                                }
                                Text("Safe")
                                    .font(.body)
                                    .fontWeight(showOnlySafePortals ? .bold : .regular)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.vertical, 12)
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
                        pendingAction = .teamChat
                        activeSheet = nil
                    }) {
                        Text("Team Chat")
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
            case .teamChat:
                break
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
    @Binding var openNeedsAttention: Bool
    var forceShowPeopleOpen: () -> Void
    var showOnlySafePortals: Bool

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .principal) {
                    MainSegmentedPicker(
                        segments: ["Chats", "Network", "Purpose"],
                        selectedIndex: $section,
                        attentionDotIndices: openNeedsAttention ? [0] : [],
                        onSelect: { idx in
                            section = idx
                            if idx == 0 {
                                // Always load chats data for tab 0 (regardless of notification dot)
                                peopleVM.fetchPeople(userId: userId, section: 0, isTabSwitch: true)
                            } else if page == .portals {
                                portalsVM.fetchPortals(userId: userId, section: idx, safeOnly: showOnlySafePortals, isTabSwitch: true)
                            } else {
                                peopleVM.fetchPeople(userId: userId, section: idx, isTabSwitch: true)
                            }
                        }
                    )
                    .id(openNeedsAttention ? "dot-on" : "dot-off")
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
                                .foregroundColor(Color.repGreen)
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
                    Button(action: { selectedProfileId = user.id }) {
                        HStack(spacing: 0) {
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
                        .padding(.leading, 16)
                        .frame(height: 64)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
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
        }
    }
}

// MARK: - Active Chat List

struct ActiveChatList: View {
    var chats: [ActiveChat]
    @ObservedObject var invitesManager: GoalTeamInvitesManager

    @State private var selectedProfileId: Int?
    @State private var selectedDirectUserId: Int?
    @State private var selectedGroupChatId: Int?
    @State private var showInvitesSheet = false 
    @AppStorage("userId") var currentUserId: Int = 0

    var body: some View {
        ZStack {
            List {
                if invitesManager.pendingInvites.count > 0 {
                    // CHANGED: From NavigationLink to Button
                    Button {
                        showInvitesSheet = true  // Show sheet instead of navigating
                    } label: {
                        HStack {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.repGreen)
                                .clipShape(Circle())
                                .padding(.trailing, 12)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("You have \(invitesManager.pendingInvites.count) pending invitation\(invitesManager.pendingInvites.count > 1 ? "s" : "")")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.primary)

                                Text("Tap to view and respond")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(UIColor.systemBackground))
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                }

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
                            Button(action: { selectedDirectUserId = user.id }) {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(user.fullName ?? "")
                                            .font(.system(size: 17, weight: .semibold))
                                        Spacer()
                                        if let dateString = chat.last_message_time,
                                           let date = ISO8601DateFormatter().date(from: dateString) {
                                            Text(date.timeAgoDisplay())
                                                .font(.caption)
                                        }
                                    }
                                    if let lastMessage = chat.last_message,
                                       let read = lastMessage.read,
                                       read == "0",
                                       let senderId = lastMessage.sender_id,
                                       senderId != currentUserId {
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
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .frame(height: 64)
                        .padding(.vertical, 16)
                        .padding(.trailing, 16)
                        .background(Color.white)
                        .listRowInsets(EdgeInsets())
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color(UIColor(red: 0.894, green: 0.894, blue: 0.894, alpha: 1.0))),
                            alignment: .bottom
                        )
                    } else if chat.type == "group", let group = chat.chat {
                        Button(action: { selectedGroupChatId = group.id }) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color(UIColor.systemGray5))
                                        .frame(width: 64, height: 64)
                                    Text(group.name?.prefix(2).uppercased() ?? "GC")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.black)
                                }
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(group.name ?? "Group Chat")
                                            .font(.system(size: 17, weight: .semibold))
                                            .lineLimit(1)
                                        Spacer()
                                        if let dateString = chat.last_message_time,
                                           let date = ISO8601DateFormatter().date(from: dateString) {
                                            Text(date.timeAgoDisplay())
                                                .font(.caption)
                                        }
                                    }
                                    if let lastMessage = chat.last_message,
                                       let read = lastMessage.read,
                                       read == "0",
                                       let senderId = lastMessage.sender_id,
                                       senderId != currentUserId {
                                        Text(lastMessage.text ?? "")
                                            .font(.system(size: 17, weight: .bold))
                                            .foregroundColor(Color.repGreen)
                                            .lineLimit(1)
                                    } else {
                                        Text(chat.last_message?.text ?? "")
                                            .font(.system(size: 17))
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .padding(.leading, 16)
                            .frame(height: 64)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 16)
                        .padding(.trailing, 16)
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
                destination: selectedDirectUserId.flatMap { id in
                    if let chat = chats.first(where: { $0.user?.id == id && $0.type == "direct" }) {
                        return AnyView(
                            Chat(
                                userId: id,
                                userName: chat.user?.fullName ?? "",
                                userPhotoURL: chat.user?.profilePictureURL
                            )
                        )
                    }
                    return AnyView(EmptyView())
                },
                isActive: Binding(
                    get: { selectedDirectUserId != nil },
                    set: { if !$0 { selectedDirectUserId = nil } }
                ),
                label: { EmptyView() }
            )
            NavigationLink(
                destination: selectedGroupChatId.flatMap { gid in
                    if let group = chats.first(where: { $0.chat?.id == gid && $0.type == "group" }) {
                        return AnyView(
                            GroupChatView(
                                viewModel: GroupChatViewModel(
                                    currentUserId: currentUserId,
                                    chatId: gid,
                                    customChatTitle: group.chat?.name,
                                    isPreview: false // 👈 Use real instance for navigation
                                )
                            )
                        )
                    }
                    return AnyView(EmptyView())
                },
                isActive: Binding(
                    get: { selectedGroupChatId != nil },
                    set: { if !$0 { selectedGroupChatId = nil } }
                ),
                label: { EmptyView() }
            )
        }
        .sheet(isPresented: $showInvitesSheet) {
            InvitesView(onDismiss: {
                // This will be called when the user is done with invites
                invitesManager.fetchPendingInvites()
            })
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