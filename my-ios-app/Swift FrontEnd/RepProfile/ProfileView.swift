//
//  ProfileView.swift
//  Rep
//
//  Created by Adam Novak on 06.15.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

import SwiftUI

// MARK: - User Model

struct User: Codable {
    let id: Int?
    let fullName: String
    let photoURL: URL?
    let repTypeAndCity: String
    let about: String
    let broadcast: String
    let skills: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case photoURL = "photo_url"
        case repTypeAndCity = "rep_type_and_city"
        case about
        case broadcast
        case skills
    }

    static let placeholder = User(
        id: nil,
        fullName: "John Doe",
        photoURL: nil,
        repTypeAndCity: "Rep Type: Lead   City: New York",
        about: "Passionate about building teams and products...",
        broadcast: "Looking for partners in NYC!",
        skills: ["Leadership", "Marketing", "Fundraising"]
    )
}

// MARK: - API Response

struct UserProfileAPIResponse: Codable {
    let result: User
}

// MARK: - Portal & Goal Models

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

    enum CodingKeys: String, CodingKey {
        case id, name, subtitle, about, categories_id, cities_id, lead_id, users_id, _c_users_count
    }
}
struct PortalsAPIResponse: Codable {
    let result: [Portal]
}

struct Goal: Identifiable, Codable {
    let id: Int
    let title: String
}
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

    var isCurrentUser: Bool = true
    var showAddPartner: Bool { false }

    func loadProfile() {
        fetchUser()
        fetchPortals()
        fetchGoals()
        fetchWrites()
    }

    func fetchUser() {
        guard let url = URL(string: "http://localhost:5000/api/user/profile?users_id=1") else { return }
        URLSession.shared.dataTask(with: url) { data, _, error in
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
    guard let url = URL(string: "http://localhost:5000/api/portals?users_id=1") else { return }
    URLSession.shared.dataTask(with: url) { data, _, error in
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
    
    struct GoalsAPIResponse: Codable {
    let aGoals: [Goal]
    }

    func fetchGoals() {
        guard let url = URL(string: "http://localhost:5000/api/goals/list?users_id=1") else { return }
        URLSession.shared.dataTask(with: url) { data, _, error in
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
    // Fetch all writes for the user
    func fetchWrites(for userId: Int) {
        guard let url = URL(string: "http://localhost:5000/api/user/writes?users_id=\(userId)") else { return }
        URLSession.shared.dataTask(with: url) { data, _, error in
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

    // Add a new write block
    func addWrite() {
        guard let url = URL(string: "http://localhost:5000/api/user/write") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
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
                    self.fetchWrites(for: self.user.id ?? 0)
                }
            }
        }.resume()
    }

    // Edit a write block
    func editWrite(_ write: WriteBlock) {
        guard let url = URL(string: "http://localhost:5000/api/user/write/\(write.id)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
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
                    self.fetchWrites(for: self.user.id ?? 0)
                }
            }
        }.resume()
    }

    // Delete a write block
    func deleteWrite(_ write: WriteBlock) {
        guard let url = URL(string: "http://localhost:5000/api/user/write/\(write.id)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let _ = data {
                DispatchQueue.main.async {
                    self.fetchWrites(for: self.user.id ?? 0)
                }
            }
        }.resume()
    }
}
    func goBack() {
        // Handle navigation back
    }

    func handleAction(_ action: String) {
        // Handle Recruit, Edit Profile, Network, etc.
    }

    func addPartner() {
        // Handle add partner action
    }

    func saveWrite() {
        previousWrite = writeText
        // Optionally, clear writeText or show a confirmation
    }
}

// MARK: - Main Profile View

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var selectedTab = 0 // 0: Rep, 1: Goals, 2: Write
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                StatusBarView()
                NavigationHeaderView(name: viewModel.user.fullName,  onBack: { dismiss() })
                ProfileInfoView(
                    photoURL: viewModel.user.photoURL,
                    repTypeAndCity: viewModel.user.repTypeAndCity,
                    skills: viewModel.user.skills
                )
                VStack(alignment: .leading, spacing: 8) {
                    if !viewModel.user.about.isEmpty {
                        Text(viewModel.user.about)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    if !viewModel.user.broadcast.isEmpty {
                        Text(viewModel.user.broadcast)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                CustomSegmentedPicker(
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
                    } else if selectedTab == 2 {
                        WriteContentView(
                            WriteContentView(viewModel: viewModel, isCurrentUser: viewModel.isCurrentUser)
                        )
                    }
                }
                .padding(.top, 8)
                .background(Color.white)
                Spacer()
                BottomBarView(
                    onAdd: { /* Add new item action */ },
                    onMessage: { /* Message action */ }
                )
            }
            .navigationBarHidden(true)
            .onAppear { viewModel.loadProfile() }
            .background(Color.white.edgesIgnoringSafeArea(.all))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(viewModel.actions, id: \.self) { action in
                            Button(action) {
                                viewModel.handleAction(action)
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
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
            // Add icons if desired
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

struct CustomSegmentedPicker: View {
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
                            .aspectRatio(contentMode: .cover)
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

// Example custom content for a card
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

struct GoalListItem: View {
    let goal: Goal
    var body: some View {
        Text(goal.title)
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
            viewModel.fetchWrites(for: viewModel.user.id ?? 0)
        }
    }
}

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

// MARK: - Placeholder for PortalPage and GoalDetailPage

struct PortalPage: View {
    let portal: Portal
    var body: some View {
        Text("Portal: \(portal.name)")
    }
}

struct GoalDetailPage: View {
    let goal: Goal
    var body: some View {
        Text("Goal: \(goal.title)")
    }
}
