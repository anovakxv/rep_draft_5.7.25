//  GoalsDetailView.swift
//  Rep
//
//  Created by Adam Novak on 06.13.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.

import SwiftUI

// MARK: - Main View

struct GoalsDetailView: View {
    let initialGoal: Goal
    @StateObject private var viewModel = GoalsDetailViewModel()
    @State private var selectedSegment = 0

    // --- Action Sheet and Sheet State ---
    @State private var showActionSheet = false
    @State private var showUpdateGoalSheet = false
    @State private var showEditGoalSheet = false
    @State private var showInviteTeamSheet = false

    // --- Reporting Increments State ---
    @State private var reportingIncrements: [ReportingIncrement] = []
    @State private var isLoadingIncrements = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // --- Custom Top Bar (matches PortalHeader style) ---
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                            .font(.system(size: 20))
                    }
                    Spacer()
                    Text(viewModel.goal.title)
                        .font(.system(size: 20, weight: .bold))
                        .lineLimit(1)
                        .truncationMode(.tail)
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

                // Progress Bar and Metrics Section
                VStack(alignment: .leading, spacing: 8) {
                    // Custom thick progress bar with square corners
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color(UIColor.systemGray5))
                            .frame(height: 34)
                        Rectangle()
                            .fill(Color.repGreen)
                            .frame(
                                width: max(0, CGFloat(viewModel.goal.progress) * UIScreen.main.bounds.width * 0.92),
                                height: 34
                            )
                    }
                    .frame(height: 34)
                    .padding(.vertical, 3)
                    HStack {
                        Text("Metric: \(viewModel.goal.metricName)")
                        Spacer()
                        Text("Goal Type: \(viewModel.goal.typeName)")
                    }
                    .font(.callout)
                    HStack {
                        // Show quota and progress as whole numbers
                        Text("Quota: \(Int(round(viewModel.goal.quota)))")
                        Spacer()
                        Text("Progress: \(Int(round(viewModel.goal.filledQuota)))")
                    }
                    .font(.callout)
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

                // Segmented Picker (updated to match PortalSegmentedPicker style)
                GoalSegmentedPicker(
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
                            LargeBarChartView(data: viewModel.goal.chartData, quota: viewModel.goal.quota)
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

                // --- Bottom Action Bar ---
                BottomGoalBar(
                    onAdd: { showActionSheet = true },
                    onMessage: { /* Optionally implement messaging */ }
                )
            }
            .background(Color.white.edgesIgnoringSafeArea(.all))
            .navigationBarHidden(true)
            .onAppear {
                // Set the initial goal instantly
                viewModel.goal = initialGoal
                // Then load the latest data from the API
                viewModel.load(goalId: initialGoal.id)
                loadReportingIncrements()
            }
            // --- Custom Action Sheet ---
            .sheet(isPresented: $showActionSheet) {
                VStack(spacing: 24) {
                    if viewModel.goal.typeName == "Recruiting" {
                        Button(action: {
                            viewModel.joinRecruitingGoal(goalId: viewModel.goal.id) { success in
                                showActionSheet = false
                                if success {
                                    viewModel.load(goalId: viewModel.goal.id)
                                }
                            }
                        }) {
                            Text("Join Team")
                                .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.vertical, 5)
                        }
                    } else {
                        Button(action: {
                            showUpdateGoalSheet = true
                            showActionSheet = false
                        }) {
                            Text("Update Progress")
                                .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.vertical, 5)
                        }
                    }
                    Button(action: {
                        showEditGoalSheet = true
                        showActionSheet = false
                    }) {
                        Text("Edit Goal")
                            .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.vertical, 5)
                    }
                    Button(action: { showActionSheet = false }) {
                        Text("Cancel")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .presentationDetents([.medium])
            }
            // --- Sheets for Actions ---
            .sheet(isPresented: $showUpdateGoalSheet) {
                UpdateGoalSheet(
                    goalId: viewModel.goal.id,
                    quota: viewModel.goal.quota,
                    metricName: viewModel.goal.metricName
                )
            }
            .sheet(isPresented: $showEditGoalSheet) {
                if viewModel.goal.id != 0, viewModel.goal.creatorId == viewModel.currentUserId {
                    EditGoalPage(
                        existingGoal: viewModel.goal,
                        portalId: viewModel.goal.portalId ?? 0,
                        userId: viewModel.currentUserId,
                        reportingIncrements: reportingIncrements.isEmpty
                            ? [
                                ReportingIncrement(id: 1, title: "Monthly"),
                                ReportingIncrement(id: 2, title: "Weekly"),
                                ReportingIncrement(id: 3, title: "Daily")
                              ]
                            : reportingIncrements
                    )
                } else {
                    Text("You do not have permission to edit this goal.")
                        .padding()
                }
            }
            .sheet(isPresented: $showInviteTeamSheet) {
                Text("Invite Team Sheet Placeholder")
            }
        }
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
}

// MARK: - Goal Segmented Picker (matches PortalSegmentedPicker style)

struct GoalSegmentedPicker: View {
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

// MARK: - ViewModel

class GoalsDetailViewModel: ObservableObject {
    @Published var goal: Goal = .placeholder
    @Published var team: [User] = []
    @Published var feed: [Feed] = []
    @Published var actions: [String] = []

    @AppStorage("jwtToken") var jwtToken: String = ""
    @AppStorage("userId") var currentUserId: Int = 0

    private let s3BaseURL = "https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/"

    func patchProfilePictureURL(_ imageName: String?) -> URL? {
        guard let imageName = imageName, !imageName.isEmpty else { return nil }
        if imageName.starts(with: "http") {
            return URL(string: imageName)
        } else {
            return URL(string: s3BaseURL + imageName)
        }
    }

    func load(goalId: Int) {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/goals/details?goals_id=\(goalId)") else { return }
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
                        chartData: apiGoal.chartData ?? [],
                        creatorId: apiGoal.creatorId ?? 0,
                        portalId: apiGoal.portalId
                    )
                    // --- FEED: Use user name if available, format timestamp, round value ---
                    let teamDict = Dictionary(uniqueKeysWithValues: (apiGoal.team ?? []).map { ($0.id, $0) })
                    self.feed = apiGoal.aLatestProgress?.compactMap { log in
                        let apiUser = teamDict[log.users_id ?? 0]
                        let userName = apiUser?.name ?? "User"
                        let formattedDate = Self.formatDateString(log.timestamp)
                        let profilePictureURL = self.patchProfilePictureURL(apiUser?.imageName)
                        return Feed(
                            id: log.id,
                            userImageName: "profile_placeholder",
                            userName: userName,
                            line1: formattedDate,
                            line2: "Value: \(Int(round(log.value ?? 0)))",
                            line3: log.note ?? "",
                            line4: "",
                            userProfilePictureURL: profilePictureURL
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
                            profilePictureURL: self.patchProfilePictureURL(apiUser.imageName),
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

    // Helper to format ISO8601 or server date string to readable date/time
    static func formatDateString(_ isoString: String?) -> String {
        guard let isoString = isoString else { return "" }
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: isoString) {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short // e.g., 7:25 PM
            return formatter.string(from: date)
        }
        // Try fallback parsing for other formats if needed
        let fallbackFormatter = DateFormatter()
        fallbackFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = fallbackFormatter.date(from: isoString) {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        return isoString
    }

    func joinRecruitingGoal(goalId: Int, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/goals/join_leave"),
              !jwtToken.isEmpty else {
            completion(false)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let params: [String: Any] = [
            "aGoalsIDs": [goalId],
            "todo": "join"
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: params)
        URLSession.shared.dataTask(with: request) { data, _, _ in
            DispatchQueue.main.async {
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let result = json["result"] as? [String: Any],
                   result["\(goalId)"] as? String == "ok" {
                    completion(true)
                } else {
                    completion(false)
                }
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
    let creatorId: Int?
    let portalId: Int?
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
    var creatorId: Int
    var portalId: Int?

    static let placeholder = Goal(
        id: 1, title: "Goal Title", subtitle: "", description: "",
        progress: 0.5, progressPercent: 50, quota: 100, filledQuota: 50,
        metricName: "Sales", typeName: "Recruiting", reportingName: "Weekly",
        quotaString: "100", valueString: "50", chartData: [],
        creatorId: 0, portalId: nil
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
    let userProfilePictureURL: URL?
}

// MARK: - Bar Chart Data Model

struct BarChartData: Identifiable, Codable {
    let id: Int
    let value: Double
    let valueLabel: String
    let bottomLabel: String

    init(id: Int, value: Double, valueLabel: String, bottomLabel: String) {
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
            if let url = feed.userProfilePictureURL {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.3))
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(feed.userName)
                    .font(.headline)
                Text(feed.line1)
                    .font(.caption)
                Text(feed.line2)
                    .font(.subheadline)
                Text("Note: \(feed.line3.isEmpty ? "NA" : feed.line3)")
                    .font(.subheadline)
                Text("Attachments: NA") // Replace with actual attachment logic if needed
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
            if let url = user.profilePictureURL {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.3))
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
            }
            Text(user.fullName ?? "")
        }
    }
}

// MARK: - Large Bar Chart View

struct LargeBarChartView: View {
    let data: [BarChartData]
    var quota: Double = 1 // Pass the goal's quota when you use this view

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .bottom, spacing: 16) { // <-- Increased spacing from 8 to 16
                ForEach(data) { item in
                    VStack(spacing: 0) {
                        // Qty label on top
                        Text(item.valueLabel)
                            .font(.caption2)
                            .foregroundColor(.black)
                            .padding(.bottom, 2)
                        Spacer(minLength: 0)
                        Rectangle()
                            .fill(Color.repGreen)
                            .frame(
                                width: 40,
                                height: {
                                    let quotaValue = quota > 0 ? quota : 1
                                    return CGFloat(item.value / quotaValue) * (geometry.size.height - 32)
                                }()
                            )
                            .cornerRadius(3)
                        // Time increment label on bottom
                        Text(item.bottomLabel)
                            .font(.caption2)
                            .foregroundColor(.black)
                            .frame(width: 32)
                            .lineLimit(1)
                            .padding(.top, 2)
                    }
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: 260)
        .padding()
        .background(Color.white)
    }
}

// MARK: - BottomGoalBar

struct BottomGoalBar: View {
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