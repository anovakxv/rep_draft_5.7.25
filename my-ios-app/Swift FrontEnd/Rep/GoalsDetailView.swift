//  GoalsDetailView.swift
//  Rep
//
//  Created by Adam Novak on 06.13.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.

import SwiftUI
import Kingfisher

// MARK: - Main View

struct GoalsDetailView: View {
    let initialGoal: Goal
    @StateObject private var viewModel = GoalsDetailViewModel()
    @State private var selectedSegment = 0

    // --- Profile Navigation ---
    @State private var selectedProfileUserId: Int? = nil

    // --- Group Chat State ---
    @State private var showChatSheet = false
    @State private var goalTeamChatId: Int? = nil
    @State private var isCreatingTeamChat = false
    @State private var chatCreationError: String?
    @AppStorage("jwtToken") private var jwtToken: String = ""
    @State private var portalToNavigateTo: Int? = nil

    // --- Unified Sheet State ---
    private enum ActiveSheet: Identifiable {
        case action
        case updateGoal
        case editGoal
        case inviteTeam

        var id: Int { hashValue }
    }
    @State private var activeSheet: ActiveSheet?
    @State private var showPortalSheet = false 

    // --- Reporting Increments State ---
    @State private var reportingIncrements: [ReportingIncrement] = []
    @State private var isLoadingIncrements = false

    @Environment(\.dismiss) private var dismiss

    // --- Delete Alert State ---
    @State private var showDeleteAlert = false
    @State private var showPayTransaction = false
    @State private var showPaymentSheet = false

    // --- Crash Prevention Guard ---
    @State private var hasAppeared = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // --- Custom Top Bar ---
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                            .font(.system(size: 20))
                            .frame(width: 44, height: 44) // Increased touch target
                            .contentShape(Rectangle())  
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text(viewModel.goal.title)
                            .font(.system(size: 20, weight: .bold))
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                        // Only show portal link if the goal has a portal
                        if let portalId = viewModel.goal.portalId, let portalName = viewModel.goal.portalName {
                            Button(action: {
                                portalToNavigateTo = portalId
                                showPortalSheet = true // Show as sheet instead of using NavigationLink
                            }) {
                                HStack(spacing: 4) {
                                    Text(portalName)
                                        .font(.caption)
                                        .lineLimit(1)
                                        .foregroundColor(Color(UIColor(red: 0.0, green: 0.4, blue: 0.0, alpha: 1.0)))
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 10))
                                        .foregroundColor(Color(UIColor(red: 0.0, green: 0.4, blue: 0.0, alpha: 1.0)))
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
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
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color(UIColor.systemGray5))
                            .frame(height: 34)
                        Rectangle()
                            .fill(Color.repGreen)
                            .frame(
                                width: max(0, min(1.0, CGFloat(viewModel.goal.progress)) * UIScreen.main.bounds.width * 0.92),
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

                GoalSegmentedPicker(
                    segments: ["Feed", "Report", "Team"],
                    selectedIndex: $selectedSegment
                )
                .padding(.horizontal)

                List {
                    if selectedSegment == 0 {
                        ForEach(viewModel.feed) { feedItem in
                            FeedCell(
                                feed: feedItem, 
                                onProfileTap: {
                                    if let userId = viewModel.getUserIdForFeed(feedItem) {
                                        selectedProfileUserId = userId
                                    }
                                }
                            )
                        }
                    } else if selectedSegment == 1 {
                        Group {
                            if viewModel.goal.chartData.isEmpty {
                                Text("No chart data available.")
                            } else {
                                LargeBarChartView(data: viewModel.goal.chartData, quota: viewModel.goal.quota)
                            }
                        }
                    } else if selectedSegment == 2 {
                        ForEach(viewModel.team) { user in
                            NavigationLink(destination: ProfileView(userId: user.id)) {
                                TeamCell(user: user)
                            }
                            .buttonStyle(PlainButtonStyle()) // Keeps the cell's original appearance
                        }
                    }
                }
                .listStyle(.plain)

                 BottomGoalBar(
                    onAdd: { activeSheet = .action },
                    onMessage: {
                        openGoalTeamChat()
                    }
                )
            }
            .disabled(isCreatingTeamChat)

            // Floating Support Button
            if viewModel.goal.typeName == "Fund" || viewModel.goal.typeName == "Sales" {
                Button(action: {
                    showPaymentSheet = true // <-- Change to use sheet instead
                }) {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color(UIColor(red: 0.0, green: 0.4, blue: 0.0, alpha: 1.0)))
                        Text("Support")
                            .fontWeight(.semibold)
                            .foregroundColor(Color(UIColor(red: 0.0, green: 0.4, blue: 0.0, alpha: 1.0)))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(UIColor(red: 0.0, green: 0.4, blue: 0.0, alpha: 1.0)), lineWidth: 2) 
                    )
                    .cornerRadius(8)
                        .shadow(
                            color: Color(.sRGB, red: 0.1, green: 0.1, blue: 0.1, opacity: 0.30), 
                            radius: 4,    
                            x: 3,
                            y: 3
                    )
                }
                .padding(.bottom, 70)
                .padding(.trailing, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .transition(.scale)
                .zIndex(2)
                .disabled(isCreatingTeamChat)
            }

            if isCreatingTeamChat {
                Color.black.opacity(0.15).ignoresSafeArea()
                ProgressView("Opening Team Chat...")
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 8)
            }

            // Navigation links
                     
            NavigationLink(
                destination: selectedProfileUserId.map { ProfileView(userId: $0) },
                isActive: Binding(
                    get: { selectedProfileUserId != nil },
                    set: { if !$0 { selectedProfileUserId = nil } }
                )
            ) {
                EmptyView()
            }
            .hidden()
            .fullScreenCover(isPresented: $showPortalSheet) {
                if let portalId = portalToNavigateTo {
                    PortalPage(portalId: portalId, userId: viewModel.currentUserId)
                }
            }
            .hidden()
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
        .navigationBarHidden(true)
        .onAppear {
            viewModel.goal = initialGoal
            viewModel.load(goalId: initialGoal.id)
            loadReportingIncrements()
            hasAppeared = true
        }
        .disabled(!hasAppeared)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .action:
                VStack(spacing: 24) {
                    // Check if user is already on the team
                    let isOnTeam = viewModel.team.contains(where: { $0.id == viewModel.currentUserId })
                    let isCreator = viewModel.goal.creatorId == viewModel.currentUserId
                    
                    // Show "Join Team" only if user is not already on the team
                    if !isOnTeam && !isCreator {
                        Button(action: {
                            viewModel.joinRecruitingGoal(goalId: viewModel.goal.id) { success in
                                activeSheet = nil
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
                    }
                    
                    // Show "Invite to Team" only if user is on the team or is creator
                    if isOnTeam || isCreator {
                        Button(action: {
                            activeSheet = .inviteTeam
                        }) {
                            Text("Invite to Team")
                                .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.vertical, 5)
                        }
                    }
                    
                    // Update Progress for non-Recruiting goals
                    if viewModel.goal.typeName != "Recruiting" {
                        Button(action: {
                            activeSheet = .updateGoal
                        }) {
                            Text("Update Progress")
                                .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.vertical, 5)
                        }
                    }
                    Button(action: {
                        activeSheet = .editGoal
                    }) {
                        Text("Edit Goal")
                            .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.vertical, 5)
                    }
                    Button(role: .destructive) {
                        activeSheet = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            showDeleteAlert = true
                        }
                    } label: {
                        Text("Delete Goal")
                            .font(.body)
                            .padding(.vertical, 5)
                    }
                    Button(action: { activeSheet = nil }) {
                        Text("Cancel")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .presentationDetents([.medium])
            case .updateGoal:
                UpdateGoalSheet(
                    goalId: viewModel.goal.id,
                    quota: viewModel.goal.quota,
                    metricName: viewModel.goal.metricName
                )
            case .editGoal:
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
            case .inviteTeam:
                InviteTeamSheet(
                    goalId: viewModel.goal.id,
                    onDone: {
                        // Refresh goal details after inviting users
                        viewModel.load(goalId: viewModel.goal.id)
                    }
                )
            }
        }
        .sheet(isPresented: $showChatSheet, onDismiss: {
            // When sheet is dismissed, clean up the chat resources
            if let chatId = goalTeamChatId {
                // Leave the specific chat room
                RealtimeSocketManager.shared.leave(chatId: chatId)
                
                // Post notification for additional cleanup
                NotificationCenter.default.post(
                    name: .cleanupGroupChat,
                    object: nil,
                    userInfo: ["chatId": chatId]
                )
            }
        }) {
            if let chatId = goalTeamChatId {
                GroupChatView(
                    viewModel: GroupChatViewModel(
                        currentUserId: viewModel.currentUserId,
                        chatId: chatId,
                        customChatTitle: "Goal Team: \(viewModel.goal.title)"
                    )
                )
                .presentationDetents([.large]) // Full screen sheet
                .interactiveDismissDisabled(false) // Allow swipe to dismiss
            }
        }
        .alert("Delete Goal?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteGoal()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this goal? This cannot be undone.")
        }
        .alert(item: $chatCreationError) { err in
            Alert(
                title: Text("Chat Error"),
                message: Text(err),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $showPaymentSheet) {
            PayTransactionView(
                portalId: viewModel.goal.portalId ?? 0,
                portalName: viewModel.goal.portalName ?? "Portal",
                goalId: viewModel.goal.id,
                goalName: viewModel.goal.title,
                transactionType: viewModel.goal.typeName == "Fund" ? .donation : .payment
            )
            .presentationDetents([.large]) // Full screen
        }
    }

        // --- Create / Open Goal Team Chat ---
    private func openGoalTeamChat() {
        guard !isCreatingTeamChat else { return }

        if let _ = goalTeamChatId {
            // Show sheet instead of using NavigationLink
            showChatSheet = true
            return
        }

        guard !jwtToken.isEmpty else {
            chatCreationError = "Not authenticated."
            return
        }

        isCreatingTeamChat = true
        chatCreationError = nil

        let memberIds = viewModel.team
            .map { $0.id }
            .filter { $0 != viewModel.currentUserId }

        guard let url = URL(string: "\(APIConfig.baseURL)/api/message/manage_chat") else {
            isCreatingTeamChat = false
            chatCreationError = "Bad URL."
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "title": "Goal Team: \(viewModel.goal.title)",
            "aAddIDs": memberIds
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isCreatingTeamChat = false
                
                if let error = error {
                    self.chatCreationError = error.localizedDescription
                    return
                }
                
                guard
                    let data = data,
                    let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let chatsId = json["chats_id"] as? Int
                else {
                    self.chatCreationError = "Failed to create chat."
                    return
                }
                
                self.goalTeamChatId = chatsId
                
                // Show sheet instead of navigation
                self.showChatSheet = true
            }
        }.resume()
    }

    // --- Delete Goal Function ---
    private func deleteGoal() {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/goals/delete"),
              let token = UserDefaults.standard.string(forKey: "jwtToken") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let params: [String: Any] = ["goals_id": viewModel.goal.id]
        request.httpBody = try? JSONSerialization.data(withJSONObject: params)
        URLSession.shared.dataTask(with: request) { _, response, _ in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    dismiss()
                }
            }
        }.resume()
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

extension Notification.Name {
    static let cleanupGroupChat = Notification.Name("cleanupGroupChat")
}

// MARK: - Goal Segmented Picker

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
    @Published var latestProgressLogs: [APIGoalProgressLog] = []


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
    
    // Helper method to get user ID from feed item
    func getUserIdForFeed(_ feedItem: Feed) -> Int? {
        return latestProgressLogs.first(where: { $0.id == feedItem.id })?.users_id
    }

    func load(goalId: Int) {
        // Create URL with num_periods parameter for the detailed view
        guard let url = URL(string: "\(APIConfig.baseURL)/api/goals/details?goals_id=\(goalId)&num_periods=7") else { return }
        var request = URLRequest(url: url)
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
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
                        portalId: apiGoal.portalId,
                        portalName: apiGoal.portalName ?? "Organization" // Fallback value
                    )

                    let teamDict = Dictionary(uniqueKeysWithValues: (apiGoal.team ?? []).map { ($0.id, $0) })

                    // Store latest progress logs for lookup
                    self.latestProgressLogs = apiGoal.aLatestProgress ?? []

                    // Get all progress logs and sort by timestamp (newest first)
                    let allLogs = apiGoal.aLatestProgress ?? []
                    let sortedLogs = allLogs.sorted { (log1, log2) -> Bool in
                        let date1 = Self.parseTimestamp(log1.timestamp)
                        let date2 = Self.parseTimestamp(log2.timestamp)
                        return date1 > date2  // Sort descending (newest first)
                    }
                    let limitedLogs = sortedLogs.prefix(20)
                    self.feed = limitedLogs.compactMap { log in
                        let apiUser = teamDict[log.users_id ?? 0]
                        let userName = apiUser?.name ?? "Unknown User"
                        let formattedDate = Self.formatDateString(log.timestamp)
                        let profilePictureURL = self.patchProfilePictureURL(apiUser?.imageName)
                        let attachments = log.aAttachments?.compactMap { attachment -> Attachment? in
                            guard let urlString = attachment.file_url,
                                let url = URL(string: urlString) else { return nil }
                            return Attachment(
                                id: attachment.id,
                                url: url,
                                isImage: attachment.is_image ?? true,
                                fileName: attachment.file_name ?? "File",
                                note: attachment.note ?? ""
                            )
                        } ?? []
                        
                        // Show only the individual transaction value, not the cumulative
                        let transactionValue = log.added_value ?? 0
                        let valueString: String
                        if self.goal.typeName == "Fund" || self.goal.typeName == "Sales" {
                            valueString = "Value: $\(Int(round(transactionValue)))"
                        } else {
                            valueString = "Value: \(Int(round(transactionValue)))"
                        }
                        return Feed(
                            id: log.id,
                            userImageName: "profile_placeholder",
                            userName: userName,
                            line1: formattedDate,
                            line2: valueString,
                            line3: log.note ?? "",
                            line4: "",
                            userProfilePictureURL: profilePictureURL,
                            attachments: attachments
                        )
                    }

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
                            other_skill: nil,
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
    
    // Helper to parse timestamp string to Date
    static func parseTimestamp(_ isoString: String?) -> Date {
        guard let isoString = isoString else { return Date.distantPast }
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: isoString) {
            return date
        }
        let fallbackFormatter = DateFormatter()
        fallbackFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = fallbackFormatter.date(from: isoString) {
            return date
        }
        return Date.distantPast
    }

    static func formatDateString(_ isoString: String?) -> String {
        guard let isoString = isoString else { return "" }
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: isoString) {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
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

    func goBack() {}
    func handleAction(_ action: String) {}
    func showProfile(for user: User) {}
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
    let portalName: String?
}

struct APIGoalProgressLog: Codable, Identifiable {
    let id: Int
    let users_id: Int?
    let added_value: Double?
    let note: String?
    let value: Double?
    let timestamp: String?
    let aAttachments: [APIAttachment]?
}

struct APIAttachment: Codable, Identifiable {
    let id: Int
    let file_url: String?
    let file_name: String?
    let is_image: Bool?
    let note: String?
}

struct APIUser: Codable, Identifiable {
    let id: Int
    let name: String?
    let imageName: String?
}

// MARK: - Models

struct Goal: Identifiable, Codable, Equatable {
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
    var portalName: String?

    static let placeholder = Goal(
        id: 1, title: "Goal Title", subtitle: "", description: "",
        progress: 0.5, progressPercent: 50, quota: 100, filledQuota: 50,
        metricName: "Sales", typeName: "Recruiting", reportingName: "Weekly",
        quotaString: "100", valueString: "50", chartData: [],
        creatorId: 0, portalId: nil, portalName: nil
    )
}
extension Goal {
    func withId(_ id: Int) -> Goal {
        var copy = self
        copy.id = id
        return copy
    }
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
    let attachments: [Attachment] 
}
struct Attachment: Identifiable {
    let id: Int
    let url: URL
    let isImage: Bool
    let fileName: String
    let note: String
}

// MARK: - Bar Chart Data Model

struct BarChartData: Identifiable, Codable, Equatable {
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
    var onProfileTap: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            if let url = feed.userProfilePictureURL {
                KFImage(url)
                    .resizable()
                    .scaledToFill()
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
                
                // Display attachments if any
                if !feed.attachments.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(feed.attachments) { attachment in
                                VStack(alignment: .leading, spacing: 4) {
                                    if attachment.isImage {
                                        KFImage(attachment.url)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 100, height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    } else {
                                        Image(systemName: "doc.fill")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 50, height: 50)
                                            .padding(.horizontal, 25)
                                    }
                                    
                                    if !attachment.note.isEmpty {
                                        Text(attachment.note)
                                            .font(.caption)
                                            .lineLimit(2)
                                            .frame(width: 100)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
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
                KFImage(url)
                    .resizable()
                    .scaledToFill()
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
    var quota: Double = 1

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(data) { item in
                    VStack(spacing: 0) {
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
                                    return min(1.0, CGFloat(item.value / quotaValue)) * (geometry.size.height - 32)
                                }()
                            )
                            .cornerRadius(3)
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

// MARK: - Invite Team Sheet

struct InviteTeamSheet: View {
    let goalId: Int
    var onDone: () -> Void
    
    @State private var users: [User] = []
    @State private var selectedUsers: Set<Int> = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var inviteSuccess = false
    
    @Environment(\.dismiss) private var dismiss
    @AppStorage("jwtToken") var jwtToken: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                List {
                    if users.isEmpty && !isLoading {
                        Text("No network members found")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                    
                    ForEach(users) { user in
                        Button {
                            if selectedUsers.contains(user.id) {
                                selectedUsers.remove(user.id)
                            } else {
                                selectedUsers.insert(user.id)
                            }
                        } label: {
                            HStack {
                                if let url = user.profilePictureURL {
                                    KFImage(url)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 40, height: 40)
                                }
                                
                                Text(user.fullName ?? "")
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if selectedUsers.contains(user.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .listStyle(.plain)
                
                if isLoading {
                    ProgressView("Loading...")
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
            }
            .navigationTitle("Invite to Team")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Invite") {
                    inviteUsers()
                }
                .disabled(selectedUsers.isEmpty)
            )
            .alert(item: $errorMessage) { error in
                Alert(title: Text("Error"), message: Text(error), dismissButton: .default(Text("OK")))
            }
            .alert("Invitation Sent", isPresented: $inviteSuccess) {
                Button("OK", role: .cancel) {
                    dismiss()
                    onDone()
                }
            } message: {
                Text("Team invitation has been sent successfully.")
            }
            .onAppear {
                loadNetworkMembers()
            }
        }
    }
    
    private func loadNetworkMembers() {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(APIConfig.baseURL)/api/user/members_of_my_network?invited_goal_id=\(goalId)") else {
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
                isLoading = false
                
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    errorMessage = "No data received"
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(UsersAPIResponse.self, from: data)
                    self.users = response.result
                } catch {
                    errorMessage = "Failed to decode response: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    private func inviteUsers() {
        guard !selectedUsers.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(APIConfig.baseURL)/api/goals/\(goalId)/team") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        
        let body: [String: Any] = [
            "users": Array(selectedUsers)
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            errorMessage = "Failed to encode request body"
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    errorMessage = "Invalid response"
                    return
                }
                
                if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    inviteSuccess = true
                } else {
                    errorMessage = "Server returned error: \(httpResponse.statusCode)"
                }
            }
        }.resume()
    }
}
