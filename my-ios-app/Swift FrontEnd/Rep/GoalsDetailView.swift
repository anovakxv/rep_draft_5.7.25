//  GoalsDetailView.swift
//  Rep
//
//  Created by Adam Novak on 06.13.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.

import SwiftUI

// MARK: - Main View

struct GoalsDetailView: View {
    @StateObject private var viewModel = GoalsDetailViewModel()
    @State private var selectedSegment = 0

    var body: some View {
        NavigationStack {
            VStack {
                // Progress Bar and Metrics Section
                VStack(alignment: .leading, spacing: 8) {
                    ProgressView(value: viewModel.goal.progress)
                        .progressViewStyle(.linear)
                        .accentColor(.repGreen)
                    HStack {
                        Text("Metric: \(viewModel.goal.metricName)")
                        Spacer()
                        Text("Goal Type: \(viewModel.goal.typeName)")
                    }
                    .font(.caption)
                    HStack {
                        Text("Progress Markers: \(viewModel.goal.reportingName)")
                        Spacer()
                        Text("Quota: \(viewModel.goal.quotaString)")
                        Spacer()
                        Text("Progress: \(viewModel.goal.valueString)")
                    }
                    .font(.caption2)
                    if !viewModel.goal.subtitle.isEmpty {
                        Text(viewModel.goal.subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    if !viewModel.goal.description.isEmpty {
                        Text(viewModel.goal.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()

                // Segmented Picker
                CustomSegmentedPicker(
                    segments: ["Feed", "Report", "Team"],
                    selectedIndex: $selectedSegment
                )
                .padding(.horizontal)

                // Table/List Section
                List {
                    if selectedSegment == 0 {
                        ForEach(viewModel.feed) { feedItem in
                            FeedCell(feed: feedItem)
                        }
                    } else if selectedSegment == 1 {
                        // Use LargeBarChartView for the report
                        if viewModel.goal.chartData.isEmpty {
                            Text("No chart data available.")
                        } else {
                            LargeBarChartView(data: viewModel.goal.chartData)
                        }
                    } else if selectedSegment == 2 {
                        ForEach(viewModel.team) { user in
                            TeamCell(user: user)
                                .onTapGesture {
                                    viewModel.showProfile(for: user)
                                }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle(viewModel.goal.title)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { viewModel.goBack() }) {
                        Image(systemName: "chevron.left")
                    }
                }
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
            .onAppear {
                viewModel.load(goalId: viewModel.goal.id)
            }
        }
    }
}

// MARK: - Custom Segmented Picker

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

// MARK: - ViewModel

class GoalsDetailViewModel: ObservableObject {
    @Published var goal: Goal = .placeholder
    @Published var team: [User] = []
    @Published var feed: [Feed] = []
    @Published var actions: [String] = []

    @AppStorage("jwtToken") var jwtToken: String = ""

    func load(goalId: Int) {
        guard let url = URL(string: "http://localhost:5000/api/goals/details?goals_id=\(goalId)") else { return }
        var request = URLRequest(url: url)
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data else { return }
            do {
                let response = try JSONDecoder().decode(GoalDetailAPIResponse.self, from: data)
                DispatchQueue.main.async {
                    let apiGoal = response.result
                    self.goal = Goal(
                        id: apiGoal.id,
                        title: apiGoal.title,
                        subtitle: apiGoal.subtitle ?? "",
                        description: apiGoal.description ?? "",
                        progress: apiGoal.progress ?? 0,
                        progressPercent: apiGoal.progress_percent ?? 0,
                        quota: apiGoal.quota ?? 0,
                        filledQuota: apiGoal.filled_quota ?? 0,
                        metricName: apiGoal.metricName ?? "",
                        typeName: apiGoal.typeName ?? "",
                        reportingName: apiGoal.reportingName ?? "",
                        quotaString: apiGoal.quotaString ?? "",
                        valueString: apiGoal.valueString ?? "",
                        chartData: apiGoal.chartData ?? []
                    )
                    self.feed = apiGoal.aLatestProgress?.map { log in
                        Feed(
                            id: log.id,
                            userImageName: "profile_placeholder",
                            userName: "User \(log.users_id ?? 0)",
                            line1: log.timestamp ?? "",
                            line2: "Value: \(log.value ?? 0)",
                            line3: log.note ?? "",
                            line4: ""
                        )
                    } ?? []
                    self.team = apiGoal.team?.map { apiUser in
                        User(
                            id: apiUser.id,
                            fullName: apiUser.name ?? "User",
                            fname: nil,
                            lname: nil,
                            username: "",
                            about: nil,
                            broadcast: nil,
                            profilePictureURL: nil,
                            imageName: apiUser.imageName ?? "profile_placeholder",
                            userType: nil,
                            city: nil,
                            skills: nil,
                            lastLogin: nil,
                            createdAt: nil,
                            updatedAt: nil,
                            lastMessage: nil,
                            lastMessageDate: nil
                        )
                    } ?? []
                }
            } catch {
                print("Goal detail decode error:", error)
            }
        }.resume()
    }

    func goBack() {
        // Handle navigation back
    }

    func handleAction(_ action: String) {
        // Handle Invite, Update, Edit, etc.
    }

    func showProfile(for user: User) {
        // Navigate to user profile
    }
}

// MARK: - API Models

struct GoalDetailAPIResponse: Codable {
    let result: APIGoalDetail
}

struct APIGoalDetail: Codable {
    let id: Int
    let title: String
    let subtitle: String?
    let description: String?
    let progress: Double?
    let progress_percent: Double?
    let quota: Double?
    let filled_quota: Double?
    let metricName: String?
    let typeName: String?
    let reportingName: String?
    let quotaString: String?
    let valueString: String?
    let chartData: [BarChartData]?
    let aLatestProgress: [APIGoalProgressLog]?
    let team: [APIUser]?
}

struct APIGoalProgressLog: Codable, Identifiable {
    let id: Int
    let users_id: Int?
    let added_value: Double?
    let note: String?
    let value: Double?
    let timestamp: String?
}

struct APIUser: Codable, Identifiable {
    let id: Int
    let name: String?
    let imageName: String?
}

// MARK: - Models

struct Goal: Identifiable, Codable {
    var id: Int
    var title: String
    var subtitle: String
    var description: String
    var progress: Double
    var progressPercent: Double
    var quota: Double
    var filledQuota: Double
    var metricName: String
    var typeName: String
    var reportingName: String
    var quotaString: String
    var valueString: String
    var chartData: [BarChartData]

    static let placeholder = Goal(
        id: 1, title: "Goal Title", subtitle: "", description: "",
        progress: 0.5, progressPercent: 50, quota: 100, filledQuota: 50,
        metricName: "Sales", typeName: "Recruiting", reportingName: "Weekly",
        quotaString: "100", valueString: "50", chartData: []
    )
}

struct Feed: Identifiable {
    let id: Int
    let userImageName: String
    let userName: String
    let line1: String
    let line2: String
    let line3: String
    let line4: String
}

// MARK: - Bar Chart Data Model

struct BarChartData: Identifiable, Codable {
    let id: UUID
    let value: Double
    let valueLabel: String
    let bottomLabel: String

    init(id: UUID = UUID(), value: Double, valueLabel: String, bottomLabel: String) {
        self.id = id
        self.value = value
        self.valueLabel = valueLabel
        self.bottomLabel = bottomLabel
    }
}

// MARK: - Cells

struct FeedCell: View {
    let feed: Feed

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(feed.userImageName)
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(feed.userName)
                    .font(.headline)
                Text(feed.line1)
                    .font(.caption)
                Text(feed.line2)
                    .font(.subheadline)
                Text(feed.line3)
                    .font(.subheadline)
                Text(feed.line4)
                    .font(.subheadline)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 8)
    }
}

struct TeamCell: View {
    let user: User
    var body: some View {
        HStack {
            Image(user.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            Text(user.fullName) // FIXED: use fullName
        }
    }
}

// MARK: - Large Bar Chart View

struct LargeBarChartView: View {
    let data: [BarChartData]

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(data) { item in
                    VStack {
                        Text(item.valueLabel)
                            .font(.caption2)
                            .foregroundColor(.black)
                        Rectangle()
                            .fill(Color.repGreen)
                            .frame(
                                width: 20,
                                height: CGFloat(item.value) / CGFloat(maxValue) * (geometry.size.height - 24)
                            )
                        Text(item.bottomLabel)
                            .font(.caption2)
                            .foregroundColor(.black)
                            .frame(width: 32)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 180)
        .padding()
        .background(Color.white)
    }

    private var maxValue: Double {
        data.map { $0.value }.max() ?? 1
    }
}
