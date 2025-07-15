//  PortalPage.swift
//  Rep
//
//  Created by Dmytro Holovko on 10.28.2023.
//  Updated by Adam Novak on 07.13.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.

import SwiftUI
import _PhotosUI_SwiftUI

// MARK: - Portal ViewModel

@MainActor
class PortalViewModel: ObservableObject {
    @Published var portalDetail: PortalDetail?
    @Published var section = 0
    @Published var isEditPresented = false
    @Published var reportingIncrements: [ReportingIncrement] = []

    @AppStorage("jwtToken") var jwtToken: String = ""

    func fetchPortalDetail(portalId: Int, userId: Int) {
        let urlString = "\(APIConfig.baseURL)/api/portal/details?portals_id=\(portalId)&user_id=\(userId)"
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data else { return }
            do {
                let response = try JSONDecoder().decode(PortalDetailResponse.self, from: data)
                DispatchQueue.main.async {
                    self.portalDetail = response.result
                }
            } catch {
                print("Decode error:", error)
            }
        }.resume()
    }

    func fetchReportingIncrements() {
        let urlString = "\(APIConfig.baseURL)/api/reporting_increments/list"
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data else { return }
            do {
                let increments = try JSONDecoder().decode([ReportingIncrement].self, from: data)
                DispatchQueue.main.async {
                    self.reportingIncrements = increments
                }
            } catch {
                print("Decode error:", error)
            }
        }.resume()
    }
}

// MARK: - Portal Page

struct PortalPage: View {
    @StateObject private var viewModel = PortalViewModel()
    let portalId: Int
    let userId: Int
    @Environment(\.dismiss) private var dismiss
    @State private var showMessageSheet = false
    @State private var selectedGoalId: Int? = nil
    @State private var showAddGoal = false

    private func leadRepUser(from portal: PortalDetail) -> User? {
        return portal.aUsers?.first
    }
    private func isCurrentUserLead(_ portal: PortalDetail) -> Bool {
        portal.aUsers?.contains(where: { $0.id == userId }) ?? false
    }

    var body: some View {
        NavigationStack {
            Group {
                if let portal = viewModel.portalDetail {
                    PortalPageContent(
                        portal: portal,
                        viewModel: viewModel,
                        dismiss: dismiss,
                        showMessageSheet: $showMessageSheet,
                        selectedGoalId: $selectedGoalId,
                        userId: userId,
                        leadRepUser: { leadRepUser(from: portal) },
                        isCurrentUserLead: isCurrentUserLead(portal),
                        showAddGoal: $showAddGoal
                    )
                    .sheet(isPresented: $showAddGoal) {
                        EditGoalPage(
                            existingGoal: nil,
                            portalId: portal.id,
                            userId: userId,
                            reportingIncrements: viewModel.reportingIncrements,
                            associatedPortalName: portal.name
                        )
                    }
                    .onAppear {
                        if viewModel.reportingIncrements.isEmpty {
                            viewModel.fetchReportingIncrements()
                        }
                    }
                } else {
                    ProgressView()
                        .onAppear {
                            viewModel.fetchPortalDetail(portalId: portalId, userId: userId)
                        }
                }
            }
        }
    }
}

// MARK: - PortalPageContent

struct PortalPageContent: View {
    let portal: PortalDetail
    @ObservedObject var viewModel: PortalViewModel
    let dismiss: DismissAction
    @Binding var showMessageSheet: Bool
    @Binding var selectedGoalId: Int?
    let userId: Int
    let leadRepUser: () -> User?
    let isCurrentUserLead: Bool
    @Binding var showAddGoal: Bool

    @State private var showPortalActionSheet = false
    @State private var pendingPortalAction: PortalActionSheetAction? = nil

    // Chat navigation state
    @State private var navigateToChat = false
    @State private var chatUserId: Int? = nil
    @State private var chatUserName: String = ""
    @State private var chatUserPhotoURL: URL? = nil

    enum PortalActionSheetAction {
        case joinTeam
        case sharePortal
        case support
        case editPortal
    }

    private var imageTabHeight: CGFloat {
        UIScreen.main.bounds.width * 9 / 16
    }

    private var chatDestination: some View {
        Group {
            if let id = chatUserId {
                Chat(
                    userId: id,
                    userName: chatUserName,
                    userPhotoURL: chatUserPhotoURL
                )
            } else {
                EmptyView()
            }
        }
    }

    private var goalDestination: some View {
        Group {
            if let goalId = selectedGoalId,
            let selectedGoal = portal.aGoals?.first(where: { $0.id == goalId }) {
                GoalsDetailView(initialGoal: selectedGoal)
            } else {
                EmptyView()
            }
        }
    }   

    var body: some View {
        VStack(spacing: 0) {
            PortalHeader(portal: portal, dismiss: dismiss)
            GeometryReader { geometry in
                let width = geometry.size.width
                ImageTabView(sections: portal.aSections ?? [])
                    .frame(width: width, height: imageTabHeight)
                    .clipped()
            }
            .frame(height: imageTabHeight)
            PortalSegmentedPicker(
                segments: ["Story", "Offering", "Results"],
                selectedIndex: $viewModel.section
            )
            .padding(.horizontal)

            PortalSectionContent(
                portal: portal,
                section: viewModel.section,
                selectedGoalId: $selectedGoalId
            )
            .padding(.horizontal)
            .padding(.top, 8)

            Spacer()
            BottomBarView(
                onAdd: { showPortalActionSheet = true },
                onMessage: {
                    if let lead = leadRepUser() {
                        chatUserId = lead.id
                        chatUserName = (lead.fname ?? "") + " " + (lead.lname ?? "")
                        chatUserPhotoURL = lead.profilePictureURL
                        navigateToChat = true
                    }
                }
            )
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
        .navigationBarHidden(true)
        .navigationTitle(portal.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Join Team") { showPortalActionSheet = true; pendingPortalAction = .joinTeam }
                    Button("Share Portal") { showPortalActionSheet = true; pendingPortalAction = .sharePortal }
                    Button("Support") { showPortalActionSheet = true; pendingPortalAction = .support }
                    Button("Edit Portal") { viewModel.isEditPresented = true }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $viewModel.isEditPresented, onDismiss: {
            viewModel.fetchPortalDetail(portalId: portal.id, userId: userId)
        }) {
            EditPortalView(portal: portal, userId: userId)
        }
        .sheet(isPresented: $showMessageSheet) {
            if let lead = leadRepUser() {
                MessageView(
                    viewModel: MessageViewModel(
                        currentUserId: userId,
                        otherUserId: lead.id,
                        otherUserName: "\(lead.fname ?? "") \(lead.lname ?? "")",
                        otherUserPhotoURL: nil
                    )
                )
            } else {
                Text("Lead Rep not found.")
            }
        }
        .sheet(isPresented: $showPortalActionSheet) {
            VStack(spacing: 24) {
                if isCurrentUserLead {
                    Button(action: {
                        showAddGoal = true
                        showPortalActionSheet = false
                    }) {
                        Text("Add Goal")
                            .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.vertical, 5)
                    }
                }
                Button(action: {
                    pendingPortalAction = .joinTeam
                    showPortalActionSheet = false
                }) {
                    Text("Join Team")
                        .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.vertical, 5)
                }
                Button(action: {
                    pendingPortalAction = .sharePortal
                    showPortalActionSheet = false
                }) {
                    Text("Share Portal")
                        .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.vertical, 5)
                }
                Button(action: {
                    pendingPortalAction = .support
                    showPortalActionSheet = false
                }) {
                    Text("Support")
                        .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.vertical, 5)
                }
                Button(action: {
                    pendingPortalAction = .editPortal
                    showPortalActionSheet = false
                }) {
                    Text("Edit Portal")
                        .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.vertical, 5)
                }
                Button(action: { showPortalActionSheet = false }) {
                    Text("Cancel")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .presentationDetents([.medium])
        }
        .onChange(of: pendingPortalAction) { action in
            guard let action = action else { return }
            switch action {
            case .joinTeam:
                // Implement join team logic
                break
            case .sharePortal:
                // Implement share portal logic
                break
            case .support:
                // Implement support logic
                break
            case .editPortal:
                viewModel.isEditPresented = true
            }
            pendingPortalAction = nil
        }
        .background(
            Group {
                NavigationLink(
                    destination: chatDestination,
                    isActive: $navigateToChat,
                    label: { EmptyView() }
                )
                .hidden()
                NavigationLink(
                    destination: goalDestination,
                    isActive: Binding(
                        get: { selectedGoalId != nil },
                        set: { isActive in if !isActive { selectedGoalId = nil } }
                    ),
                    label: { EmptyView() }
                )
                .hidden()
            }
        )
    }
}

// MARK: - PortalHeader

struct PortalHeader: View {
    let portal: PortalDetail
    let dismiss: DismissAction

    var body: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                    .font(.system(size: 20))
            }
            Spacer()
            Text(portal.name)
                .font(.system(size: 20, weight: .bold))
            Spacer()
            Color.clear.frame(width: 24, height: 24)
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

// MARK: - PortalSectionContent

struct PortalSectionContent: View {
    let portal: PortalDetail
    let section: Int
    @Binding var selectedGoalId: Int?

    var body: some View {
        Group {
            if section == 0 {
                PortalStorySection(portal: portal)
            } else if section == 1 {
                PortalOfferingSection(portal: portal)
            } else if section == 2 {
                PortalResultsSection(goals: portal.aGoals ?? [], selectedGoalId: $selectedGoalId)
            }
        }
    }
}

// MARK: - Image Tab View

struct ImageTabView: View {
    let sections: [PortalSection]

    var body: some View {
        TabView {
            ForEach(sections.flatMap { $0.aFiles }) { file in
                if let urlString = file.url, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                                .clipped()
                        } else if phase.error != nil {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .overlay(Text("Image Error").foregroundColor(.secondary))
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .overlay(Text("Loading...").foregroundColor(.secondary))
                        }
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(Text("No Image").foregroundColor(.secondary))
                }
            }
        }
        .tabViewStyle(PageTabViewStyle())
    }
}

// MARK: - Portal Segmented Picker

struct PortalSegmentedPicker: View {
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

// MARK: - Content Sections

struct PortalStorySection: View {
    let portal: PortalDetail
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Leads")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(portal.aUsers ?? []) { user in
                        VStack {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 28, height: 28)
                            Text("\(user.fname?.prefix(1) ?? "")\(user.lname?.prefix(1) ?? "")")
                                .font(.caption2)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            Divider()
            // Show Story Text Blocks
            ForEach((portal.aTexts ?? []).filter { ($0.section ?? "") == "story" }) { block in
                VStack(alignment: .leading, spacing: 4) {
                    if let title = block.title, !title.isEmpty {
                        Text(title)
                            .font(.title2)
                            .fontWeight(.medium)
                    }
                    if let text = block.text, !text.isEmpty {
                        Text(text)
                            .font(.body)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

struct PortalOfferingSection: View {
    let portal: PortalDetail
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("We Offer")
                .font(.headline)
            Text(portal.about ?? "")
                .font(.body)
        }
    }
}

struct PortalResultsSection: View {
    let goals: [Goal]
    @Binding var selectedGoalId: Int?
    var body: some View {
        ForEach(goals) { goal in
            VStack {
                Button(action: {
                    selectedGoalId = goal.id
                }) {
                    GoalListItem(goal: goal)
                }
                .buttonStyle(PlainButtonStyle())
                Divider()
            }
        }
    }
}

// MARK: - Models

struct PortalDetailResponse: Codable {
    let result: PortalDetail
}

struct PortalDetail: Identifiable, Codable {
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
    let aGoals: [Goal]?
    let aPortalUsers: [PortalUser]?
    let aTexts: [PortalText]?
    let aSections: [PortalSection]?
    let aUsers: [User]?
}

struct PortalUser: Identifiable, Codable {
    let id: Int
}

struct PortalText: Identifiable, Codable {
    let id: Int
    let portal_id: Int
    let title: String?
    let text: String?
    let section: String?
    let created_at: String?
    let updated_at: String?
}

struct PortalSection: Identifiable, Codable {
    let id: Int
    let title: String
    let aFiles: [PortalFile]
}

struct PortalFile: Identifiable, Codable {
    let id: Int
    let url: String?
}

// MARK: - Goal List Item & Detail

struct BarChartView: View {
    let data: [BarChartData]

    var maxValue: Double {
        data.map { $0.value }.max() ?? 1
    }

    var body: some View {
        VStack(spacing: 2) {
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(data) { bar in
                    Rectangle()
                        .fill(Color.repGreen)
                        .frame(width: 14, height: CGFloat(bar.value / maxValue) * 40)
                        .cornerRadius(3)
                }
            }
            HStack(spacing: 6) {
                ForEach(data) { bar in
                    Text(bar.bottomLabel)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 14)
                }
            }
        }
        .frame(width: 70, height: 56)
    }
}