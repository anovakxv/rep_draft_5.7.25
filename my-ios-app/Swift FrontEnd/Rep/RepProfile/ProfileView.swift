//  ProfileView.swift
//  Rep
//
//  Created by Adam Novak on 06.15.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.

import SwiftUI
import Kingfisher

// MARK: - Unified User Model

struct User: Identifiable, Codable, Equatable {
    let id: Int
    let fullName: String?
    let fname: String?
    let lname: String?
    let username: String?
    let about: String?
    let broadcast: String?
    let profilePictureURL: URL?
    let imageName: String?
    let userType: String?
    let city: String?
    let skills: [SkillModel]?
    let other_skill: String?
    let lastLogin: String?
    let createdAt: String?
    let updatedAt: String?
    let lastMessage: String?
    let lastMessageDate: String?

    var displayName: String {
        if let fullName = fullName, !fullName.isEmpty {
            return fullName
        }
        return [fname, lname].compactMap { $0 }.joined(separator: " ")
    }

    var repTypeAndCity: String {
        let type = userType ?? ""
        let cityStr = city ?? ""
        if !type.isEmpty && !cityStr.isEmpty {
            return "Rep Type: \(type)   City: \(cityStr)"
        } else if !type.isEmpty {
            return "Rep Type: \(type)"
        } else if !cityStr.isEmpty {
            return "City: \(cityStr)"
        }
        return ""
    }

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case fname
        case lname
        case username
        case about
        case broadcast
        case profilePictureURL = "profile_picture_url"
        case userType = "user_type"
        case city
        case skills
        case lastLogin = "last_login"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastMessage = "last_message"
        case lastMessageDate = "last_message_date"
        case other_skill = "other_skill"
        case imageName
    }

    init(
        id: Int,
        fullName: String?,
        fname: String?,
        lname: String?,
        username: String?,
        about: String?,
        broadcast: String?,
        profilePictureURL: URL?,
        imageName: String?,
        userType: String?,
        city: String?,
        skills: [SkillModel]?,
        other_skill: String?,
        lastLogin: String?,
        createdAt: String?,
        updatedAt: String?,
        lastMessage: String?,
        lastMessageDate: String?
    ) {
        self.id = id
        self.fullName = fullName
        self.fname = fname
        self.lname = lname
        self.username = username
        self.about = about
        self.broadcast = broadcast
        self.profilePictureURL = profilePictureURL
        self.imageName = imageName
        self.userType = userType
        self.city = city
        self.skills = skills
        self.other_skill = other_skill
        self.lastLogin = lastLogin
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastMessage = lastMessage
        self.lastMessageDate = lastMessageDate
    }

    // Flexible decoding for skills ([SkillModel] or [String])
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        fullName = try container.decodeIfPresent(String.self, forKey: .fullName)
        fname = try container.decodeIfPresent(String.self, forKey: .fname)
        lname = try container.decodeIfPresent(String.self, forKey: .lname)
        username = try container.decodeIfPresent(String.self, forKey: .username)
        about = try container.decodeIfPresent(String.self, forKey: .about)
        broadcast = try container.decodeIfPresent(String.self, forKey: .broadcast)
        imageName = try container.decodeIfPresent(String.self, forKey: .imageName)
        userType = try container.decodeIfPresent(String.self, forKey: .userType)
        city = try container.decodeIfPresent(String.self, forKey: .city)
        lastLogin = try container.decodeIfPresent(String.self, forKey: .lastLogin)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        lastMessage = try container.decodeIfPresent(String.self, forKey: .lastMessage)
        lastMessageDate = try container.decodeIfPresent(String.self, forKey: .lastMessageDate)
        other_skill = try container.decodeIfPresent(String.self, forKey: .other_skill)

        // Flexible skills decoding
        if let skillModels = try? container.decode([SkillModel].self, forKey: .skills) {
            skills = skillModels
        } else if let skillStrings = try? container.decode([String].self, forKey: .skills) {
            skills = skillStrings.enumerated().map { SkillModel(id: $0.offset, title: $0.element) }
        } else {
            skills = nil
        }

        // Patch profile_picture_url to always be a full URL or nil
        let urlString = try container.decodeIfPresent(String.self, forKey: .profilePictureURL)
        if let urlString, !urlString.isEmpty {
            if urlString.starts(with: "http") {
                profilePictureURL = URL(string: urlString)
            } else {
                profilePictureURL = URL(string: "https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/\(urlString)")
            }
        } else {
            profilePictureURL = nil
        }
    }

    static let placeholder = User(
        id: 0,
        fullName: "John Doe",
        fname: "John",
        lname: "Doe",
        username: "johndoe",
        about: "Passionate about building teams and products...",
        broadcast: "Looking for partners in NYC!",
        profilePictureURL: nil,
        imageName: "profile_placeholder",
        userType: "Lead",
        city: "New York",
        skills: [
            SkillModel(id: 1, title: "Leadership"),
            SkillModel(id: 2, title: "Marketing"),
            SkillModel(id: 3, title: "Fundraising")
        ],
        other_skill: nil,
        lastLogin: nil,
        createdAt: nil,
        updatedAt: nil,
        lastMessage: nil,
        lastMessageDate: nil
    )
}

// MARK: - API Response

struct UserProfileAPIResponse: Codable {
    let result: User
}

struct GoalsAPIResponse: Codable {
    let aGoals: [Goal]
}

struct PortalsAPIResponse: Codable {
    let result: [Portal]
}

// MARK: - Portal Model

struct Portal: Identifiable, Codable {
    let id: Int
    let name: String
    let subtitle: String?
    let about: String?
    let categories_id: Int?
    let cities_id: Int?
    let lead_id: Int?
    let users_id: Int?
    let _c_users_count: Int?
    let mainImageUrl: String?
}

// MARK: - WriteBlock Model

struct WriteBlock: Identifiable, Codable {
    let id: Int
    var title: String?
    var content: String
    var order: Int?
    var created_at: String?
    var updated_at: String?
}

// MARK: - ViewModel

class ProfileViewModel: ObservableObject {
    @Published var user: User = .placeholder
    @Published var isLoaded: Bool = false
    @Published var portals: [Portal] = []
    @Published var goals: [Goal] = []
    @Published var actions: [String] = []
    @Published var writeBlocks: [WriteBlock] = []
    @Published var writeText: String = ""
    @Published var writeTitle: String = ""
    @Published var editingWrite: WriteBlock? = nil
    @Published var availableSkills: [SkillModel] = []
    @Published var isBlocked: Bool = false

    @AppStorage("jwtToken") var jwtToken: String = ""
    @AppStorage("userId") var loggedInUserId: Int = 0

    let viewedUserId: Int
    var isCurrentUser: Bool { viewedUserId == loggedInUserId }
    var showAddPartner: Bool { false }

    init(userId: Int) {
        self.viewedUserId = userId
        fetchAvailableSkills()
    }

    func loadProfile() {
        isLoaded = false
        fetchUser()
        fetchPortals()
        fetchGoals()
        fetchWrites(for: viewedUserId)
        fetchAvailableSkills()
        fetchBlockStatus()
    }

    func fetchAvailableSkills() {
        fetchSkills(jwtToken: jwtToken) { [weak self] skills in
            DispatchQueue.main.async {
                self?.availableSkills = skills
            }
        }
    }

    func fetchUser() {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/user/profile?users_id=\(viewedUserId)") else { return }
        var request = URLRequest(url: url)
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let http = response as? HTTPURLResponse {
                if http.statusCode == 401 || http.statusCode == 403 {
                    AuthSession.handleUnauthorized("ProfileViewModel.fetchUser")
                    return
                }
                if http.statusCode < 200 || http.statusCode >= 300 {
                    DispatchQueue.main.async { self.isLoaded = true }
                    return
                }
            }
            if let error = error {
                print("User fetch error:", error)
            }
            guard let data = data else {
                DispatchQueue.main.async { self.isLoaded = true }
                return
            }
            print("User fetch data:", String(data: data, encoding: .utf8) ?? "nil")
            do {
                let apiResponse = try JSONDecoder().decode(UserProfileAPIResponse.self, from: data)
                DispatchQueue.main.async {
                    self.user = apiResponse.result
                    self.isLoaded = true
                }
            } catch {
                print("User decode error:", error)
                DispatchQueue.main.async { self.isLoaded = true }
            }
        }.resume()
    }

    func fetchPortals() {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/portal/filter_network_portals?user_id=\(viewedUserId)&tab=open") else { return }
        var request = URLRequest(url: url)
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        URLSession.shared.dataTask(with: request) { data, response, _ in
            if let http = response as? HTTPURLResponse {
                if http.statusCode == 401 || http.statusCode == 403 {
                    AuthSession.handleUnauthorized("ProfileViewModel.fetchPortals")
                    return
                }
                if http.statusCode < 200 || http.statusCode >= 300 {
                    return
                }
            }
            guard let data = data else { return }
            do {
                let apiResponse = try JSONDecoder().decode(PortalsAPIResponse.self, from: data)
                DispatchQueue.main.async {
                    self.portals = apiResponse.result
                }
            } catch {
                print("Portals decode error:", error)
            }
        }.resume()
    }

    func fetchGoals() {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/goals/list?users_id=\(viewedUserId)") else { return }
        var request = URLRequest(url: url)
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        URLSession.shared.dataTask(with: request) { data, response, _ in
            if let http = response as? HTTPURLResponse {
                if http.statusCode == 401 || http.statusCode == 403 {
                    AuthSession.handleUnauthorized("ProfileViewModel.fetchGoals")
                    return
                }
                if http.statusCode < 200 || http.statusCode >= 300 {
                    return
                }
            }
            guard let data = data else { return }
            do {
                let apiResponse = try JSONDecoder().decode(GoalsAPIResponse.self, from: data)
                DispatchQueue.main.async {
                    self.goals = apiResponse.aGoals
                }
            } catch {
                print("Goals decode error:", error)
            }
        }.resume()
    }

    func fetchWrites(for userId: Int) {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/user/writes?users_id=\(userId)") else { return }
        var request = URLRequest(url: url)
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        URLSession.shared.dataTask(with: request) { data, response, _ in
            if let http = response as? HTTPURLResponse {
                if http.statusCode == 401 || http.statusCode == 403 {
                    AuthSession.handleUnauthorized("ProfileViewModel.fetchWrites")
                    return
                }
                if http.statusCode < 200 || http.statusCode >= 300 {
                    return
                }
            }
            guard let data = data else { return }
            do {
                let response = try JSONDecoder().decode([String: [WriteBlock]].self, from: data)
                DispatchQueue.main.async {
                    self.writeBlocks = response["result"] ?? []
                }
            } catch {
                print("Write fetch error:", error)
            }
        }.resume()
    }


    func addWrite() {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/user/write") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        let body: [String: Any] = [
            "title": writeTitle,
            "content": writeText
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let _ = data {
                DispatchQueue.main.async {
                    self.writeText = ""
                    self.writeTitle = ""
                    self.fetchWrites(for: self.viewedUserId)
                }
            }
        }.resume()
    }

    func editWrite(_ write: WriteBlock) {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/user/write/\(write.id)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        var body: [String: Any] = [
            "title": write.title ?? "",
            "content": write.content
        ]
        if let order = write.order {
            body["order"] = order
        }
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let _ = data {
                DispatchQueue.main.async {
                    self.editingWrite = nil
                    self.writeTitle = ""
                    self.writeText = ""
                    self.fetchWrites(for: self.viewedUserId)
                }
            }
        }.resume()
    }

    func deleteWrite(_ write: WriteBlock) {
        print("deleteWrite called for id:", write.id)
        guard let url = URL(string: "\(APIConfig.baseURL)/api/user/write/\(write.id)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let _ = data {
                DispatchQueue.main.async {
                    self.fetchWrites(for: self.viewedUserId)
                }
            }
        }.resume()
    }

    // --- Block/Unblock logic ---
    func fetchBlockStatus() {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/user/is_blocked?users_id=\(viewedUserId)") else { return }
        var request = URLRequest(url: url)
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else { return }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let blocked = json["is_blocked"] as? Bool {
                DispatchQueue.main.async {
                    self.isBlocked = blocked
                }
            }
        }.resume()
    }

    func blockUser(completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/user/block") else {
            completion(false, "Invalid URL")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        let body: [String: Any] = [
            "users_id": viewedUserId
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(false, "No response")
                return
            }
            if httpResponse.statusCode == 200 {
                DispatchQueue.main.async { self.isBlocked = true }
                completion(true, nil)
            } else {
                let message = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                completion(false, message)
            }
        }.resume()
    }

    func unblockUser(completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/user/unblock") else {
            completion(false, "Invalid URL")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        let body: [String: Any] = [
            "users_id": viewedUserId
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(false, "No response")
                return
            }
            if httpResponse.statusCode == 200 {
                DispatchQueue.main.async { self.isBlocked = false }
                completion(true, nil)
            } else {
                let message = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                completion(false, message)
            }
        }.resume()
    }
    
    func flagUser(reason: String = "", completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/user/flag_user") else {
            completion(false, "Invalid URL")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        let body: [String: Any] = [
            "users_id": viewedUserId,
            "reason": reason
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(false, "No response")
                return
            }
            if httpResponse.statusCode == 200 {
                completion(true, nil)
            } else {
                let message = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                completion(false, message)
            }
        }.resume()
    }
    
    func goBack() {}
    
    func handleAction(_ action: String, editProfile: @escaping () -> Void) {
        if action == "Edit Profile" { editProfile() }
    }
    
    func addPartner() {}

    // MARK: - Add to Network
    func addToNetwork(completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/user/network_action") else {
            completion(false, "Invalid URL")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        let body: [String: Any] = [
            "action": "add",
            "user_id": loggedInUserId,
            "target_user_id": viewedUserId
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(false, "No response")
                return
            }
            if httpResponse.statusCode == 200 {
                completion(true, nil)
            } else {
                let message = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                completion(false, message)
            }
        }.resume()
    }
}

// MARK: - Main Profile View

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    @State private var selectedTab = 0
    @State private var showNetworkResultAlert = false
    @State private var networkResultMessage = ""
    @Environment(\.dismiss) private var dismiss

    @State private var pendingAction: PendingAction? = nil
    @State private var reportingIncrements: [ReportingIncrement] = []
    @State private var isLoadingIncrements = false
    @State private var showPolicy = false
    @State private var showFlagConfirmation = false
    @State private var showSettings = false
    @AppStorage("acceptedTermsOfUse") private var acceptedTermsOfUse: Bool = false

    // --- Messaging navigation state ---
    @State private var selectedUser: User? = nil
    @State private var showMessageView = false

    // For navigation to GoalsDetailView
    @StateObject private var editProfileVM = ProfileInfoViewModel(
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

    enum ActiveSheet: Identifiable {
        case actionSheet
        case profileActionMenu
        case addPurpose
        case addGoal

        var id: Int {
            switch self {
            case .actionSheet: return 1
            case .profileActionMenu: return 2
            case .addPurpose: return 3
            case .addGoal: return 4
            }
        }
    }

    @State private var activeSheet: ActiveSheet?
    @State private var showEditProfile = false
    @State private var shouldNavigateToEditProfile = false // Intermediate state

    enum PendingAction {
        case editProfile
        case addPurpose
        case addGoal
        case logout
    }

    init(userId: Int) {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(userId: userId))
    }

    private var stickyHeader: some View {
        ProfileSegmentedPicker(
            segments: ["Rep", "Goals", "Write"],
            selectedIndex: $selectedTab
        )
        .padding(.horizontal)
        .background(Color.white)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                NavigationHeaderView(
                    name: viewModel.user.fullName ?? "", 
                    onBack: { dismiss() },
                    showSettings: viewModel.isCurrentUser,
                    onSettings: { showSettings = true }
                )
                
                if viewModel.isLoaded && viewModel.user.id != 0 {
                    ScrollView {
                        ProfileMainContent(
                            viewModel: viewModel,
                            selectedTab: $selectedTab,
                            mappedSkillTitles: mappedSkillTitles,
                            stickyHeader: { AnyView(stickyHeader) }
                        )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !viewModel.isLoaded {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack {
                        Spacer()
                        Text("User not found.")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                
                BottomBarView(
                    onAdd: {
                        if viewModel.isCurrentUser {
                            activeSheet = .actionSheet
                        } else {
                            activeSheet = .profileActionMenu
                        }
                    },
                    onMessage: {
                        print("Messaging: loggedInUserId=\(viewModel.loggedInUserId), selectedUserId=\(viewModel.user.id)")
                        // Delay setting state to avoid UI contention
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            selectedUser = viewModel.user
                            showMessageView = true
                        }
                    }
                )
                // NavigationLink for EditProfile (not a sheet)
                .fullScreenCover(isPresented: $showEditProfile) {
                    EditProfileView(
                        viewModel: editProfileVM,
                        onSave: { updatedUser in
                            if let updatedUser = updatedUser {
                                viewModel.user = updatedUser
                                viewModel.isLoaded = true
                            } else {
                                viewModel.loadProfile()
                            }
                            showEditProfile = false
                        }
                    )
                    .interactiveDismissDisabled()
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.loadProfile()
                loadReportingIncrements()
            }
            .background(Color.white.edgesIgnoringSafeArea(.all))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if viewModel.isCurrentUser {
                            Button("Edit Profile") {
                                pendingAction = .editProfile
                            }
                        }
                        ForEach(viewModel.actions, id: \.self) { action in
                            Button(action) {
                                viewModel.handleAction(action, editProfile: {
                                    pendingAction = .editProfile
                                })
                            }
                        }
                        if viewModel.isCurrentUser {
                            Button("Logout") {
                                pendingAction = .logout
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .actionSheet:
                    VStack(spacing: 24) {
                        if viewModel.isCurrentUser {
                            Button(action: {
                                pendingAction = .addPurpose
                                activeSheet = nil
                            }) {
                                Text("Add Purpose")
                                    .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.vertical, 5)
                            }
                            Button(action: {
                                pendingAction = .addGoal
                                activeSheet = nil
                            }) {
                                Text("Add Goal")
                                    .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.vertical, 5)
                            }
                            Button(action: {
                                pendingAction = .editProfile
                                activeSheet = nil
                            }) {
                                Text("Edit Profile")
                                    .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.vertical, 5)
                            }
                            // Removed "Logout" and "Policy" buttons from here
                        }
                        Button(action: { activeSheet = nil }) {
                            Text("Cancel")
                                .foregroundColor(.secondary)
                                .font(.body)
                        }
                    }
                    .padding()
                    .presentationDetents([.medium])
                case .profileActionMenu:
                    VStack(spacing: 24) {
                        Button(action: {
                            viewModel.addToNetwork { success, message in
                                DispatchQueue.main.async {
                                    networkResultMessage = success ? "Added to your network!" : (message ?? "Failed to add to network.")
                                    activeSheet = nil
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                        showNetworkResultAlert = true
                                    }
                                }
                            }
                        }) {
                            Text("+ to NTWK")
                                .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.vertical, 5)
                        }
                        if viewModel.isBlocked {
                            Button(action: {
                                viewModel.unblockUser { success, message in
                                    DispatchQueue.main.async {
                                        networkResultMessage = success ? "User unblocked." : (message ?? "Failed to unblock user.")
                                        activeSheet = nil
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                            showNetworkResultAlert = true
                                        }
                                    }
                                }
                            }) {
                                Text("Unblock User")
                                    .foregroundColor(.red)
                                    .font(.body)
                                    .fontWeight(.bold)
                                    .padding(.vertical, 5)
                            }
                        } else {
                            Button(action: {
                                viewModel.blockUser { success, message in
                                    DispatchQueue.main.async {
                                        networkResultMessage = success ? "User blocked." : (message ?? "Failed to block user.")
                                        activeSheet = nil
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                            showNetworkResultAlert = true
                                        }
                                    }
                                }
                            }) {
                                Text("Block User")
                                    .foregroundColor(.red)
                                    .font(.body)
                                    .padding(.vertical, 5)
                            }
                        }
                        Button(action: { showFlagConfirmation = true }) {
                            Text("Flag as Inappropriate")
                                .foregroundColor(.red)
                                .font(.body)
                                .padding(.vertical, 5)
                        }
                        .alert("Flag User?", isPresented: $showFlagConfirmation) {
                            Button("Flag", role: .destructive) {
                                viewModel.flagUser { success, message in
                                    networkResultMessage = success ? "User flagged as inappropriate." : (message ?? "Failed to flag user.")
                                    showNetworkResultAlert = true
                                }
                                activeSheet = nil
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("Are you sure you want to flag this person as inappropriate?")
                        }
                        Button(action: { activeSheet = nil }) {
                            Text("Cancel")
                                .foregroundColor(.secondary)
                                .font(.body)
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
                            users_id: viewModel.user.id,
                            _c_users_count: nil,
                            mainImageUrl: nil,
                            aGoals: [],
                            aPortalUsers: [],
                            aTexts: [],
                            aSections: [],
                            aUsers: [],
                            aLeads: []
                        ),
                        userId: viewModel.user.id
                    )

                case .addGoal:
                    EditGoalPage(
                        existingGoal: nil,
                        portalId: nil,
                        userId: viewModel.user.id,
                        reportingIncrements: reportingIncrements.isEmpty
                            ? [
                                ReportingIncrement(id: 1, title: "Monthly"),
                                ReportingIncrement(id: 2, title: "Weekly"),
                                ReportingIncrement(id: 3, title: "Daily")
                            ]
                            : reportingIncrements,
                        associatedPortalName: nil
                    )
                }
            }
            .navigationDestination(isPresented: $showPolicy) {
                TermsOfUseView()
            }    
            .alert(isPresented: $showNetworkResultAlert) {
                Alert(title: Text(networkResultMessage))
            }
            .onChange(of: pendingAction) { action in
                guard let action = action else { return }
                switch action {
                case .editProfile:
                    UIApplication.shared.endEditing()
                    updateEditProfileVM()
                    activeSheet = nil
                    pendingAction = nil
                    shouldNavigateToEditProfile = true
                case .addPurpose:
                    activeSheet = .addPurpose
                    pendingAction = nil
                case .addGoal:
                    activeSheet = .addGoal
                    pendingAction = nil
                case .logout:
                    logoutAndClearSession()
                    pendingAction = nil
                }
            }
            .onChange(of: shouldNavigateToEditProfile) { newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        showEditProfile = true
                        shouldNavigateToEditProfile = false
                    }
                }
            }
            .onChange(of: activeSheet) { sheet in
                if sheet == nil {
                    viewModel.fetchGoals()
                }
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
            }
            // THIS IS THE FIX: Use a fullScreenCover for MessageView
            .fullScreenCover(isPresented: $showMessageView) {
                if let user = selectedUser {
                    DelayedMessageView(
                        user: user,
                        loggedInUserId: viewModel.loggedInUserId
                    )
                }
            }
        }
    }
    
    // Helper to update the edit profile view model before showing the sheet
    private func updateEditProfileVM() {
        editProfileVM.profileInfo = ProfileInfo(
            firstName: viewModel.user.fname ?? "",
            lastName: viewModel.user.lname ?? "",
            skills: Set(viewModel.user.skills ?? []),
            type: RepTypeModel(rawValue: viewModel.user.userType ?? "") ?? .lead,
            cityName: viewModel.user.city ?? "",
            image: nil,
            about: viewModel.user.about ?? "",
            broadcast: viewModel.user.broadcast ?? "",
            otherSkill: ""
        )
    }

    private func loadReportingIncrements() {
        guard !isLoadingIncrements else { return }
        isLoadingIncrements = true
        guard let url = URL(string: "\(APIConfig.baseURL)/api/goals/reporting_increments"),
              let token = UserDefaults.standard.string(forKey: "jwtToken") else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, _, _ in
            defer { isLoadingIncrements = false }
            guard let data = data else { return }
            if let decoded = try? JSONDecoder().decode(ReportingIncrementsResponse.self, from: data) {
                DispatchQueue.main.async {
                    self.reportingIncrements = decoded.reportingIncrements
                }
            }
        }.resume()
    }

    private func logoutAndClearSession() {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/user/logout") else {
            viewModel.jwtToken = ""
            viewModel.loggedInUserId = 0
            acceptedTermsOfUse = false
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if !viewModel.jwtToken.isEmpty {
            request.setValue("Bearer \(viewModel.jwtToken)", forHTTPHeaderField: "Authorization")
        }
        URLSession.shared.dataTask(with: request) { _, _, _ in
            DispatchQueue.main.async {
                viewModel.jwtToken = ""
                viewModel.loggedInUserId = 0
                acceptedTermsOfUse = false
            }
        }.resume()
    }

    private var mappedSkillTitles: [String] {
        guard let userSkills = viewModel.user.skills else { return [] }
        return userSkills.map { $0.title }
    }
}

// Helper subview to reduce type-checking complexity
struct ProfileMainContent: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Binding var selectedTab: Int
    let mappedSkillTitles: [String]
    let stickyHeader: () -> AnyView

    var body: some View {
        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
            ProfileInfoView(
                photoURL: viewModel.user.profilePictureURL,
                city: viewModel.user.city,
                skills: mappedSkillTitles
            )
            ProfileBroadcastView(broadcast: viewModel.user.broadcast)
            Section(header: stickyHeader()) {
                ProfileTabContent(
                    selectedTab: selectedTab,
                    viewModel: viewModel
                )
            }
        }
    }
}

struct DelayedMessageView: View {
    let user: User
    let loggedInUserId: Int
    @State private var showActualView = false

    var body: some View {
        Group {
            if showActualView {
                MessageView(
                    viewModel: .init(
                        currentUserId: loggedInUserId,
                        otherUserId: user.id,
                        otherUserName: user.displayName,
                        otherUserPhotoURL: user.profilePictureURL
                    )
                )
            } else {
                VStack {
                    Spacer()
                    ProgressView("Opening chat...")
                        .padding()
                    Spacer()
                }
                .onAppear {
                    // Delay actual presentation to ensure clean context
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        showActualView = true
                    }
                }
            }
        }
    }
}

// MARK: - Subviews for breaking up complexity

struct ProfileBroadcastView: View {
    let broadcast: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let broadcast = broadcast, !broadcast.isEmpty {
                Text(broadcast)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

struct ProfileTabContent: View {
    let selectedTab: Int
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        ZStack {
            switch selectedTab {
            case 0:
                ProfileRepSection(
                    portals: viewModel.portals,
                    isCurrentUser: viewModel.isCurrentUser,
                    showAddPartner: viewModel.showAddPartner,
                    addPartnerAction: viewModel.addPartner,
                    userId: viewModel.user.id
                )
                .padding(.top, 8)
                .background(Color.white)
            case 1:
                GoalsListSection(
                    goals: viewModel.goals,
                    isCurrentUser: viewModel.isCurrentUser,
                    showAddGoal: .constant(false)
                )
                .padding(.top, 8)
                .background(Color.white)
            case 2:
                WriteContentView(
                    viewModel: viewModel,
                    isCurrentUser: viewModel.isCurrentUser
                )
                .padding(.top, 8)
                .background(Color.white)
            default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}

// MARK: - Profile Rep Section

struct ProfileRepSection: View {
    let portals: [Portal]
    let isCurrentUser: Bool
    let showAddPartner: Bool
    let addPartnerAction: () -> Void
    let userId: Int

    var body: some View {
        VStack(spacing: 0) {
            ForEach(portals, id: \.id) { portal in
                NavigationLink(destination: PortalPage(portalId: portal.id, userId: userId)) {
                    PortalItem(portal: portal)
                }
            }
            if showAddPartner {
                Button("Add Partner") {
                    addPartnerAction()
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}

// MARK: - Goals List Section

struct GoalsListSection: View {
    let goals: [Goal]
    let isCurrentUser: Bool
    @Binding var showAddGoal: Bool

    var body: some View {
        VStack(spacing: 0) {
            ForEach(goals) { goal in
                NavigationLink(destination: GoalsDetailView(initialGoal: goal)) {
                    GoalListItem(goal: goal)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                if goal.id != goals.last?.id {
                    Divider()
                        .background(Color(UIColor(red: 0.894, green: 0.894, blue: 0.894, alpha: 1.0)))
                }
            }
            if goals.isEmpty {
                Text("No goals yet.")
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
        }
    }
}

// MARK: - Profile Segmented Picker

struct ProfileSegmentedPicker: View {
    let segments: [String]
    @Binding var selectedIndex: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(segments.indices, id: \.self) { index in
                Button(action: {
                    selectedIndex = index
                }) {
                    Text(segments[index])
                        .fontWeight(.medium)
                        .foregroundColor(selectedIndex == index ? .white : .black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(selectedIndex == index ? Color.black : Color.white)
                }
                .buttonStyle(PlainButtonStyle())
                .overlay(
                    Rectangle()
                        .frame(width: index < segments.count - 1 ? 1 : 0)
                        .foregroundColor(Color(UIColor(red: 0.894, green: 0.894, blue: 0.894, alpha: 1.0))),
                    alignment: .trailing
                )
            }
        }
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.black, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - Supporting Views

struct NavigationHeaderView: View {
    let name: String
    let onBack: () -> Void
    var showSettings: Bool = false
    var onSettings: (() -> Void)? = nil

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                    .font(.system(size: 20))
                    .frame(width: 44, height: 44, alignment: .center)
                    .contentShape(Rectangle()) 
            }
            Spacer()
            Text(name)
                .font(.system(size: 20, weight: .bold))
                .frame(height: 44, alignment: .center)
            Spacer()
            if showSettings, let onSettings = onSettings {
                Button(action: onSettings) {
                    Image(systemName: "line.3.horizontal")
                        .foregroundColor(Color(red: 0.549, green: 0.78, blue: 0.365))
                        .font(.system(size: 20, weight: .semibold))
                        .frame(width: 32, height: 44, alignment: .center)
                }
                .accessibilityLabel("Open Settings")
            } else {
                Color.clear.frame(width: 32, height: 44)
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 15)
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(UIColor(red: 0.894, green: 0.894, blue: 0.894, alpha: 1.0))),
            alignment: .bottom
        )
    }
}

struct ProfileInfoView: View {
    let photoURL: URL?
    let city: String?
    let skills: [String]

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            if let url = photoURL {
                KFImage(url)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 108, height: 108)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 108, height: 108)
            }

            VStack(alignment: .leading, spacing: 7) {
                if let city = city, !city.isEmpty {
                    Text(city)
                        .font(.system(size: 17, weight: .bold))
                }
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(skills, id: \.self) { skill in
                        Text(skill)
                            .font(.system(size: 17))
                    }
                }
            }
            .padding(.top, 5)
            Spacer()
        }
        .padding(15)
    }
}

struct WriteContentView: View {
    @ObservedObject var viewModel: ProfileViewModel
    let isCurrentUser: Bool

    @State private var showDeleteAlert = false
    @State private var blockToDelete: WriteBlock?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if viewModel.writeBlocks.isEmpty {
                Text("No content yet.")
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                ForEach(viewModel.writeBlocks) { write in
                    VStack(alignment: .leading, spacing: 4) {
                        if let title = write.title, !title.isEmpty {
                            Text(title)
                                .font(.title3)
                                .fontWeight(.medium)
                        }
                        Text(write.content)
                            .font(.title3)
                        if isCurrentUser {
                            HStack {
                                Button("Edit") {
                                    viewModel.editingWrite = write
                                    viewModel.writeTitle = write.title ?? ""
                                    viewModel.writeText = write.content
                                }
                                .font(.title3)
                                .foregroundColor(.blue)
                                Spacer()
                                Button("Delete") {
                                    blockToDelete = write
                                    showDeleteAlert = true
                                }
                                .font(.title3)
                                .foregroundColor(.red)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                }
            }
            if isCurrentUser {
                Divider()
                Text(viewModel.editingWrite == nil ? "Add new block:" : "Edit block:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                TextField("Title", text: $viewModel.writeTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.title2)
                    .padding(.horizontal)
                TextEditor(text: $viewModel.writeText)
                    .font(.title3)
                    .frame(height: 120)
                    .padding(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)
                Button(action: {
                    if let editing = viewModel.editingWrite {
                        print("Editing write with id: \(editing.id)")
                        var updated = editing
                        updated.title = viewModel.writeTitle
                        updated.content = viewModel.writeText
                        viewModel.editWrite(updated)
                    } else {
                        print("Adding new write")
                        viewModel.addWrite()
                    }
                }) {
                    Text(viewModel.editingWrite == nil ? "Save" : "Update")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                        .padding(.top, 8)
                }
                .buttonStyle(PlainButtonStyle())
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(.vertical)
        .onAppear {
            viewModel.fetchWrites(for: viewModel.viewedUserId)
        }
        .alert("Delete Writing Block", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let block = blockToDelete {
                    viewModel.deleteWrite(block)
                    blockToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                blockToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this writing block? This action cannot be undone.")
        }
    }
}

// MARK: - BottomBarView

struct BottomBarView: View {
    var onAdd: () -> Void
    var onMessage: () -> Void

    var body: some View {
        HStack(spacing: 30) {
            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 291, height: 41)
                    .background(Color(UIColor(red: 0.482, green: 0.749, blue: 0.294, alpha: 1.0)))
                    .cornerRadius(6)
                    .shadow(color: Color(UIColor(red: 0.482, green: 0.749, blue: 0.294, alpha: 0.1)), radius: 3, x: 1, y: 4)
            }
            Button(action: onMessage) {
                Image(systemName: "message")
                    .font(.system(size: 20))
                    .foregroundColor(.black)
            }
        }
        .frame(height: 51)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(UIColor(red: 0.894, green: 0.894, blue: 0.894, alpha: 1.0))),
            alignment: .top
        )
    }
}