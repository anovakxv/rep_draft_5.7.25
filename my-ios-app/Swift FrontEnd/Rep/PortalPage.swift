//  PortalPage.swift
//  Rep
//
//  Created by Dmytro Holovko on 10.28.2023.
//  Updated by Adam Novak on 06.20.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.

import SwiftUI
import _PhotosUI_SwiftUI

// MARK: - Portal ViewModel

@MainActor
class PortalViewModel: ObservableObject {
    @Published var portalDetail: PortalDetail?
    @Published var section = 0
    @Published var isEditPresented = false

    // JWT token for authentication
    @AppStorage("jwtToken") var jwtToken: String = ""

    func fetchPortalDetail(portalId: Int, userId: Int) {
        let urlString = "http://localhost:5000/api/portal/details?portals_id=\(portalId)&user_id=\(userId)"
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        // Add JWT token to the request header
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
}

// MARK: - Portal Page

struct PortalPage: View {
    @StateObject private var viewModel = PortalViewModel()
    let portalId: Int
    let userId: Int
    @Environment(\.dismiss) private var dismiss
    @State private var showMessageSheet = false
    @State private var selectedGoalId: Int? = nil

    // Helper to get the Lead Rep user object
    private func leadRepUser(from portal: PortalDetail) -> User? {
        guard let leadId = portal.lead_id else { return nil }
        return portal.aUsers.first(where: { $0.id == leadId })
    }

    var body: some View {
        NavigationStack {
            Group {
                if let portal = viewModel.portalDetail {
                    VStack(spacing: 0) {
                        // Custom Back Header
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
                        .frame(height: 60)
                        .padding(.horizontal, 15)
                        .background(Color.white)
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color(UIColor(red: 0.894, green: 0.894, blue: 0.894, alpha: 1.0))),
                            alignment: .bottom
                        )
                        GeometryReader { geometry in
                            ImageTabView(sections: portal.aSections)
                                .frame(width: geometry.size.width, height: geometry.size.width * 9 / 16)
                                .clipped()
                        }
                        .frame(height: UIScreen.main.bounds.width * 9 / 16)
                        PortalSegmentedPicker(
                            segments: ["Story", "Offering", "Results"],
                            selectedIndex: $viewModel.section
                        )
                        .padding(.horizontal)

                        Group {
                            if viewModel.section == 0 {
                                PortalStorySection(portal: portal)
                            } else if viewModel.section == 1 {
                                PortalOfferingSection(portal: portal)
                            } else if viewModel.section == 2 {
                                PortalResultsSection(goals: portal.aGoals, selectedGoalId: $selectedGoalId)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)

                        Spacer()
                        // --- Bottom Bar (matches ProfileView) ---
                        HStack(spacing: 30) {
                            Button(action: {
                                // Your action here, e.g., join team
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .frame(width: 291, height: 41)
                                    .background(Color(UIColor(red: 0.482, green: 0.749, blue: 0.294, alpha: 1.0)))
                                    .cornerRadius(6)
                                    .shadow(color: Color(UIColor(red: 0.482, green: 0.749, blue: 0.294, alpha: 0.1)), radius: 3, x: 1, y: 4)
                            }
                            if let lead = leadRepUser(from: portal) {
                                Button(action: { showMessageSheet = true }) {
                                    Image(systemName: "message")
                                        .font(.system(size: 20))
                                        .foregroundColor(.black)
                                }
                                .accessibilityLabel("Message Lead Rep")
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
                        // --- End Bottom Bar ---
                    }
                    .background(Color.white.edgesIgnoringSafeArea(.all))
                    .navigationBarHidden(true)
                    .navigationTitle(portal.name)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Menu {
                                Button("Join Team") { /* ... */ }
                                Button("Share Portal") { /* ... */ }
                                Button("Support") { /* ... */ }
                                Button("Edit Portal") { viewModel.isEditPresented = true }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                        }
                    }
                    .sheet(isPresented: $viewModel.isEditPresented) {
                        EditPortalView(portal: portal, userId: userId)
                    }
                    .sheet(isPresented: $showMessageSheet) {
                        if let lead = leadRepUser(from: portal) {
                            MessageView(
                                viewModel: MessageViewModel(
                                    currentUserId: userId,
                                    otherUserId: lead.id,
                                    otherUserName: "\(lead.fname ?? "") \(lead.lname ?? "")",
                                    otherUserPhotoURL: nil // Provide a URL if available
                                )
                            )
                        } else {
                            Text("Lead Rep not found.")
                        }
                    }
                    // Navigation to GoalsDetailView
                    .background(
                        NavigationLink(
                            destination: selectedGoalId.map { GoalsDetailView(goalId: $0) },
                            tag: selectedGoalId ?? -1,
                            selection: Binding(
                                get: { selectedGoalId },
                                set: { selectedGoalId = $0 }
                            ),
                            label: { EmptyView() }
                        )
                        .hidden()
                    )
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

// MARK: - Content Sections

struct PortalStorySection: View {
    let portal: PortalDetail
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Leads")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(portal.aUsers) { user in
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
            Text("Description")
                .font(.headline)
            Text(portal.about ?? "")
                .font(.body)
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
    let aGoals: [Goal]
    let aPortalUsers: [PortalUser]
    let aTexts: [PortalText]
    let aSections: [PortalSection]
    let aUsers: [User]
}

struct PortalUser: Identifiable, Codable {
    let id: Int
}

struct PortalText: Identifiable, Codable {
    let id: Int
    let text: String
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
