//
//  PortalPage.swift
//  Rep 
//
//  Created by Dmytro Holovko on 10.28.2023.
//  Updated by Adam Novak on 06.15.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.


import SwiftUI
import _PhotosUI_SwiftUI
import SwiftUI

// MARK: - Portal ViewModel

@MainActor
class PortalViewModel: ObservableObject {
    @Published var portalDetail: PortalDetail?
    @Published var section = 0
    @Published var isEditPresented = false

    func fetchPortalDetail(portalId: Int, userId: Int) {
        let urlString = "http://localhost:5000/api/portal/details?portals_id=\(portalId)&user_id=\(userId)"
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { data, _, error in
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

    var body: some View {
        Group {
            if let portal = viewModel.portalDetail {
                VStack(spacing: 0) {
                    GeometryReader { geometry in
                        ImageTabView(sections: portal.aSections)
                            .frame(width: geometry.size.width, height: geometry.size.width * 9 / 16)
                            .clipped()
                    }
                    .frame(height: UIScreen.main.bounds.width * 9 / 16)

                    CustomSegmentedPicker(
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
                            PortalResultsSection(goals: portal.aGoals)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    Spacer()
                }
                .background(Color.white.edgesIgnoringSafeArea(.all))
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
                    EditPortalView(portal: portal)
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

// MARK: - Segmented Picker

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
    var body: some View {
        ForEach(goals) { goal in
            VStack {
                NavigationLink(destination: GoalDetailPage(goal: goal)) {
                    GoalListItem
                }
                Divider()
            }
        }
    }
}

// MARK: - Edit Portal View (Stub)

struct EditPortalView: View {
    let portal: PortalDetail
    var body: some View {
        Text("Edit Portal View Placeholder for \(portal.name)")
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

struct Goal: Identifiable, Codable {
    let id: Int
    let title: String
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

struct User: Identifiable, Codable {
    let id: Int
    let fname: String?
    let lname: String?
}

// MARK: - Goal List Item & Detail

struct GoalListItem: View {
    let goal: Goal
    var body: some View {
        HStack {
            Text(goal.title)
                .font(.headline)
            Spacer()
        }
        .padding()
        .background(Color.white)
    }
}

struct GoalDetailPage: View {
    let goal: Goal
    var body: some View {
        Text("Goal: \(goal.title)")
    }