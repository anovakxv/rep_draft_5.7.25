//  ProfileView.swift
//  Rep
//
//  Created by Adam Novak on 06.15.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.

import SwiftUI

// MARK: - Unified User Model

struct User: Identifiable, Codable {
    let id: Int
    let fullName: String
    let fname: String?
    let lname: String?
    let username: String
    let about: String?
    let broadcast: String?
    let profilePictureURL: URL?
    let imageName: String
    let userType: String?
    let city: String?
    let skills: [String]?
    let lastLogin: String?
    let createdAt: String?
    let updatedAt: String?
    let lastMessage: String?
    let lastMessageDate: String?

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
        case imageName
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
        skills: ["Leadership", "Marketing", "Fundraising"],
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

// MARK: - ProfileCard Model

struct ProfileCard: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageUrl: String
    let isCustomBackground: Bool
    let backgroundColor: Color?
    let customContent: AnyView?

    init(
        title: String,
        description: String,
        imageUrl: String,
        isCustomBackground: Bool = false,
        backgroundColor: Color? = nil,
        customContent: AnyView? = nil
    ) {
        self.title = title
        self.description = description
        self.imageUrl = imageUrl
        self.isCustomBackground = isCustomBackground
        self.backgroundColor = backgroundColor
        self.customContent = customContent
    }
}

// MARK: - ViewModel

class ProfileViewModel: ObservableObject {
    @Published var user: User = .placeholder
    @Published var portals: [Portal] = []
    @Published var goals: [Goal] = []
    @Published var actions: [String] = []
    @Published var writeBlocks: [WriteBlock] = []
    @Published var writeText: String = ""
    @Published var writeTitle: String = ""
    @Published var editingWrite: WriteBlock? = nil
    @Published var profileCards: [ProfileCard] = [
        ProfileCard(
            title: "Economic Advancement",
            description: "Increasing my income by 50% in 2 years.",
            imageUrl: "https://cdn.builder.io/api/v1/image/assets/TEMP/2460fce7187bd62a3df0309aa8e16ea1c3c5db54"
        ),
        ProfileCard(
            title: "Boys & Girls Club",
            description: "4 volunteer hours per month",
            imageUrl: "https://cdn.builder.io/api/v1/image/assets/TEMP/d4a6a0d0ddb849dfe1884db98a4ec691983e1a16",
            isCustomBackground: true,
            backgroundColor: Color(UIColor(red: 0, green: 0.576, blue: 0.816, alpha: 1.0)),
            customContent: AnyView(BGCLogoView())
        ),
        ProfileCard(
            title: "Education",
            description: "16 hours of coding school per month",
            imageUrl: "https://cdn.builder.io/api/v1/image/assets/TEMP/f265c57b67c280fd401dba8430b0d38587d04450"
        ),
        ProfileCard(
            title: "EGT Solar",
            description: "Sourcing commercial solar leads",
            imageUrl: "https://cdn.builder.io/api/v1/image/assets/TEMP/68d3c97d890eeff370980bab2545ba73b2617eb7"
        ),
        ProfileCard(
            title: "Networked Capital",
            description: "Building Super-Intelligence together",
            imageUrl: "https://cdn.builder.io/api/v1/image/assets/TEMP/461e6c1c1c471394cd09dedd26d51cd4cd28f236"
        )
    ]
    @Published var availableSkills: [SkillModel] = []

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
        fetchUser()
        fetchPortals()
        fetchGoals()
        fetchWrites(for: viewedUserId)
        fetchAvailableSkills()
    }

    func fetchAvailableSkills() {
        fetchSkills(jwtToken: jwtToken) { [weak self] skills in
            DispatchQueue.main.async {
                self?.availableSkills = skills
            }
        }
    }

    func fetchUser() {
        guard let url = URL(string: "http://localhost:5000/api/user/profile?users_id=\(viewedUserId)") else { return }
        var request = URLRequest(url: url)
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data else { return }
            do {
                let apiResponse = try JSONDecoder().decode(UserProfileAPIResponse.self, from: data)
                DispatchQueue.main.async {
                    self.user = apiResponse.result
                }
            } catch {
                print("User decode error:", error)
            }
        }.resume()
    }

    func fetchPortals() {
        guard let url = URL(string: "http://localhost:5000/api/portals?users_id=\(viewedUserId)") else { return }
        var request = URLRequest(url: url)
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        URLSession.shared.dataTask(with: request) { data, _, error in
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
        guard let url = URL(string: "http://localhost:5000/api/goals/list?users_id=\(viewedUserId)") else { return }
        var request = URLRequest(url: url)
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        URLSession.shared.dataTask(with: request) { data, _, error in
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
        guard let url = URL(string: "http://localhost:5000/api/user/writes?users_id=\(userId)") else { return }
        var request = URLRequest(url: url)
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        URLSession.shared.dataTask(with: request) { data, _, error in
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
        guard let url = URL(string: "http://localhost:5000/api/user/write") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        let body: [String: Any] = [
            "title": writeTitle,
            "content": writeText,
            "order": (writeBlocks.last?.order ?? 0) + 1
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
        guard let url = URL(string: "http://localhost:5000/api/user/write/\(write.id)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        let body: [String: Any] = [
            "title": write.title ?? "",
            "content": write.content,
            "order": write.order ?? 0
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let _ = data {
                DispatchQueue.main.async {
                    self.editingWrite = nil
                    self.fetchWrites(for: self.viewedUserId)
                }
            }
        }.resume()
    }

    func deleteWrite(_ write: WriteBlock) {
        guard let url = URL(string: "http://localhost:5000/api/user/write/\(write.id)") else { return }
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

    func goBack() {}
    func handleAction(_ action: String, editProfile: @escaping () -> Void) {
        if action == "Edit Profile" { editProfile() }
    }
    func addPartner() {}
}

// MARK: - Main Profile View

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    @State private var selectedTab = 0
    @State private var showAddPurpose = false
    @State private var showMessageSheet = false
    @State private var showAddGoal = false
    @State private var showEditProfile = false
    @Environment(\.dismiss) private var dismiss

    init(userId: Int) {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(userId: userId))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                StatusBarView()
                NavigationHeaderView(name: viewModel.user.fullName,  onBack: { dismiss() })
                ProfileInfoView(
                    photoURL: viewModel.user.profilePictureURL,
                    repTypeAndCity: viewModel.user.repTypeAndCity,
                    skills: mappedSkillTitles
                )
                VStack(alignment: .leading, spacing: 8) {
                    if let about = viewModel.user.about, !about.isEmpty {
                        Text(about)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    if let broadcast = viewModel.user.broadcast, !broadcast.isEmpty {
                        Text(broadcast)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                ProfileSegmentedPicker(
                    segments: ["Rep", "Goals", "Write"],
                    selectedIndex: $selectedTab
                )
                .padding(.horizontal)
                Group {
                    if selectedTab == 0 {
                        ScrollView {
                            VStack(spacing: 0) {
                                ProfileCardsSection(cards: viewModel.profileCards)
                                    .padding(.bottom, 16)
                                if viewModel.isCurrentUser {
                                    Button(action: { showAddPurpose = true }) {
                                        HStack {
                                            Image(systemName: "plus.circle.fill")
                                                .foregroundColor(.green)
                                            Text("Add Purpose")
                                                .fontWeight(.bold)
                                                .foregroundColor(.green)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color(UIColor(red: 0.95, green: 1.0, blue: 0.95, alpha: 1.0)))
                                        .cornerRadius(8)
                                        .padding(.horizontal)
                                    }
                                    .padding(.bottom, 12)
                                }
                                ForEach(viewModel.portals) { portal in
                                    NavigationLink(destination: PortalPage(portal: portal)) {
                                        PortalItem(portal: portal)
                                    }
                                    .padding(.horizontal)
                                }
                                if viewModel.showAddPartner {
                                    Button("Add Partner") {
                                        viewModel.addPartner()
                                    }
                                    .frame(maxWidth: .infinity, alignment: .center)
                                }
                            }
                        }
                    } else if selectedTab == 1 {
                        VStack(spacing: 0) {
                            if viewModel.isCurrentUser {
                                Button(action: { showAddGoal = true }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Add Goal")
                                            .fontWeight(.bold)
                                            .foregroundColor(.green)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(UIColor(red: 0.95, green: 1.0, blue: 0.95, alpha: 1.0)))
                                    .cornerRadius(8)
                                    .padding(.horizontal)
                                }
                                .padding(.bottom, 12)
                            }
                            List {
                                ForEach(viewModel.goals) { goal in
                                    NavigationLink(destination: GoalDetailPage(goal: goal)) {
                                        GoalListItem(goal: goal)
                                    }
                                }
                                if viewModel.goals.isEmpty {
                                    Text("No goals yet.")
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal)
                                }
                            }
                            .listStyle(PlainListStyle())
                        }
                    } else if selectedTab == 2 {
                        WriteContentView(
                            viewModel: viewModel,
                            isCurrentUser: viewModel.isCurrentUser
                        )
                    }
                }
                .padding(.top, 8)
                .background(Color.white)
                Spacer()
                BottomBarView(
                    onAdd: { /* Add new item action */ },
                    onMessage: { showMessageSheet = true },
                    onAction: {
                        if viewModel.isCurrentUser {
                            showEditProfile = true
                        }
                    },
                    isCurrentUser: viewModel.isCurrentUser
                )
            }
            .navigationBarHidden(true)
            .onAppear { viewModel.loadProfile() }
            .background(Color.white.edgesIgnoringSafeArea(.all))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if viewModel.isCurrentUser {
                            Button("Edit Profile") {
                                showEditProfile = true
                            }
                        }
                        ForEach(viewModel.actions, id: \.self) { action in
                            Button(action) {
                                viewModel.handleAction(action, editProfile: {
                                    showEditProfile = true
                                })
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
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
                        users_id: viewModel.user.id,
                        _c_users_count: nil,
                        aGoals: [],
                        aPortalUsers: [],
                        aTexts: [],
                        aSections: [],
                        aUsers: []
                    ),
                    userId: viewModel.user.id
                )
            }
            .sheet(isPresented: $showAddGoal) {
                AddGoalSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showMessageSheet) {
                MessageView(
                    viewModel: MessageViewModel(
                        currentUserId: viewModel.loggedInUserId,
                        otherUserId: viewModel.user.id,
                        otherUserName: viewModel.user.fullName,
                        otherUserPhotoURL: viewModel.user.profilePictureURL
                    )
                )
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(
                    viewModel: ProfileInfoViewModel(
                        profileInfo: ProfileInfo(
                            firstName: viewModel.user.fname ?? "",
                            lastName: viewModel.user.lname ?? "",
                            skills: Set(
                                (viewModel.user.skills ?? []).compactMap { skillName in
                                    viewModel.availableSkills.first(where: { $0.title == skillName })
                                }
                            ),
                            type: RepTypeModel(rawValue: viewModel.user.userType ?? "") ?? .lead,
                            cityName: viewModel.user.city ?? "",
                            image: nil,
                            about: viewModel.user.about ?? "",
                            broadcast: viewModel.user.broadcast ?? "",
                            otherSkill: ""
                        ),
                        mode: .edit
                    )
                )
            }
        }
    }

    // Helper to map user.skills [String] to [SkillModel.title] for display
    private var mappedSkillTitles: [String] {
        guard let userSkills = viewModel.user.skills else { return [] }
        // Try to match with availableSkills, fallback to the string if not found
        return userSkills.map { skillName in
            viewModel.availableSkills.first(where: { $0.title == skillName })?.title ?? skillName
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
                        .padding(.vertical, 8)
                        .background(selectedIndex == index ? Color.black : Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 0)
                                .stroke(Color.black, lineWidth: 1)
                        )
                }
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 0))
    }
}

// MARK: - Supporting Views

struct StatusBarView: View {
    var body: some View {
        HStack {
            Text("9:41")
                .font(.system(size: 14))
                .foregroundColor(.black)
            Spacer()
        }
        .frame(height: 48)
        .padding(.horizontal, 19)
        .background(Color(UIColor(red: 0.976, green: 0.976, blue: 0.976, alpha: 1.0)))
    }
}

struct NavigationHeaderView: View {
    let name: String
    let onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                    .font(.system(size: 20))
            }
            Spacer()
            Text(name)
                .font(.system(size: 20, weight: .bold))
            Spacer()
            Color.clear.frame(width: 24, height: 24)
        }
        .frame(height: 60)
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
    let repTypeAndCity: String
    let skills: [String]

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            if let url = photoURL {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.3))
                }
                .frame(width: 108, height: 108)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 108, height: 108)
            }

            VStack(alignment: .leading, spacing: 7) {
                Text(repTypeAndCity)
                    .font(.system(size: 17, weight: .bold))
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

struct ProfileCardsSection: View {
    let cards: [ProfileCard]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(cards) { card in
                ProfileCardView(card: card)
            }
        }
        .padding(.horizontal, 15)
    }
}

struct ProfileCardView: View {
    let card: ProfileCard

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            if card.isCustomBackground, let customContent = card.customContent {
                customContent
                    .frame(width: 178, height: 90)
            } else if card.isCustomBackground, let backgroundColor = card.backgroundColor {
                backgroundColor
                    .frame(width: 178, height: 90)
            } else {
                AsyncImage(url: URL(string: "\(card.imageUrl)&format=webp")) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if phase.error != nil {
                        Color.gray
                    } else {
                        Color.gray.opacity(0.3)
                    }
                }
                .frame(width: 178, height: 90)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(card.title)
                    .font(.system(size: 17, weight: .bold))
                Text(card.description)
                    .font(.system(size: 17))
            }
            .padding(.top, 3)
            Spacer()
        }
        .padding(.vertical, 14)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(UIColor(red: 0.894, green: 0.894, blue: 0.894, alpha: 1.0))),
            alignment: .bottom
        )
    }
}

struct BGCLogoView: View {
    var body: some View {
        ZStack {
            Color(UIColor(red: 0, green: 0.576, blue: 0.816, alpha: 1.0))
            VStack(spacing: 1) {
                AsyncImage(url: URL(string: "https://cdn.builder.io/api/v1/image/assets/TEMP/d4a6a0d0ddb849dfe1884db98a4ec691983e1a16&format=webp")) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else if phase.error != nil {
                        Color.gray
                    } else {
                        Color.gray.opacity(0.3)
                    }
                }
                .frame(width: 131, height: 50)
                VStack(spacing: 0) {
                    Text("BOYS & GIRLS CLUBS")
                        .font(.custom("Alkalami", size: 12))
                        .foregroundColor(.white)
                    Text("OF THE SIOUX EMPIRE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
                .lineSpacing(1.2)
            }
            .frame(width: 131)
        }
    }
}

struct WriteContentView: View {
    @ObservedObject var viewModel: ProfileViewModel
    let isCurrentUser: Bool

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
                                .font(.headline)
                        }
                        Text(write.content)
                            .font(.body)
                        if isCurrentUser {
                            HStack {
                                Button("Edit") {
                                    viewModel.editingWrite = write
                                    viewModel.writeTitle = write.title ?? ""
                                    viewModel.writeText = write.content
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                                Button("Delete") {
                                    viewModel.deleteWrite(write)
                                }
                                .font(.caption)
                                .foregroundColor(.red)
                            }
                        }
                    }
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
                    .padding(.horizontal)
                TextEditor(text: $viewModel.writeText)
                    .frame(height: 120)
                    .padding(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)
                Button(viewModel.editingWrite == nil ? "Save" : "Update") {
                    if let editing = viewModel.editingWrite {
                        var updated = editing
                        updated.title = viewModel.writeTitle
                        updated.content = viewModel.writeText
                        viewModel.editWrite(updated)
                    } else {
                        viewModel.addWrite()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(UIColor(red: 0.482, green: 0.749, blue: 0.294, alpha: 1.0)))
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .onAppear {
            viewModel.fetchWrites(for: viewModel.viewedUserId)
        }
    }
}

struct BottomBarView: View {
    var onAdd: () -> Void
    var onMessage: () -> Void
    var onAction: () -> Void
    var isCurrentUser: Bool

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
            if isCurrentUser {
                Button(action: onAction) {
                    Image(systemName: "pencil")
                        .font(.system(size: 20))
                        .foregroundColor(.black)
                }
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

// --- Placeholders for missing views ---

struct GoalDetailPage: View {
    let goal: Goal
    var body: some View {
        Text(goal.title)
    }
}

struct AddGoalSheet: View {
    @ObservedObject var viewModel: ProfileViewModel
    var body: some View {
        Text("Add Goal Sheet")
    }
}
