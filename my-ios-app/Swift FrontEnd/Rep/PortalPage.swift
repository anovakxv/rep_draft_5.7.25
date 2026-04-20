//  PortalPage.swift
//  Rep
//
//  Created by Dmytro Holovko on 10.28.2023.
//  Updated by Adam Novak on 07.20.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.

import SwiftUI
import _PhotosUI_SwiftUI
import Combine
import Kingfisher
import SafariServices

// MARK: - Orientation Observer

class OrientationObserver: ObservableObject {
    @Published var isLandscape: Bool = UIDevice.current.orientation.isLandscape

    private var cancellable: AnyCancellable?

    init() {
        let notification = UIDevice.orientationDidChangeNotification
        cancellable = NotificationCenter.default.publisher(for: notification)
            .sink { _ in
                let orientation = UIDevice.current.orientation
                self.isLandscape = orientation == .landscapeLeft || orientation == .landscapeRight
            }
    }
}

// MARK: - Portal ViewModel

@MainActor
class PortalViewModel: ObservableObject {
    @Published var portalDetail: PortalDetail?
    @Published var portalGoals: [Goal] = []
    @Published var section = 0
    @Published var isEditPresented = false
    @Published var reportingIncrements: [ReportingIncrement] = []

    @AppStorage("jwtToken") var jwtToken: String = ""

    // CRASH FIX: Request cancellation tracking
    nonisolated(unsafe) private var detailTask: URLSessionDataTask?
    nonisolated(unsafe) private var goalsTask: URLSessionDataTask?
    nonisolated(unsafe) private var incrementsTask: URLSessionDataTask?

    deinit {
        cancelAllRequests()
    }

    nonisolated func cancelAllRequests() {
        detailTask?.cancel()
        goalsTask?.cancel()
        incrementsTask?.cancel()
    }

    func fetchPortalDetail(portalId: Int, userId: Int) {
        // CRASH FIX: Cancel previous request
        detailTask?.cancel()
        let urlString = "\(APIConfig.baseURL)/api/portal/details?portals_id=\(portalId)&user_id=\(userId)"
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        detailTask = URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data else { return }
            do {
                let response = try JSONDecoder().decode(PortalDetailResponse.self, from: data)
                DispatchQueue.main.async {
                    self.portalDetail = response.result
                }
            } catch {
                print("Decode error:", error)
            }
        }
        detailTask?.resume()
    }

    func fetchPortalGoals(portalId: Int) {
        // CRASH FIX: Cancel previous request
        goalsTask?.cancel()
        let urlString = "\(APIConfig.baseURL)/api/goals/portal?portals_id=\(portalId)"
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        goalsTask = URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data else { return }
            do {
                let response = try JSONDecoder().decode(PortalGoalsResponse.self, from: data)
                DispatchQueue.main.async {
                    self.portalGoals = response.aGoals
                }
            } catch {
                print("Decode error:", error)
            }
        }
        goalsTask?.resume()
    }

    func fetchReportingIncrements() {
        // CRASH FIX: Cancel previous request
        incrementsTask?.cancel()
        let urlString = "\(APIConfig.baseURL)/api/reporting_increments/list"
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        incrementsTask = URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data else { return }
            do {
                let increments = try JSONDecoder().decode([ReportingIncrement].self, from: data)
                DispatchQueue.main.async {
                    self.reportingIncrements = increments
                }
            } catch {
                print("Decode error:", error)
            }
        }
        incrementsTask?.resume()
    }
}

extension PortalViewModel {
        func flagPortal(portalId: Int, reason: String = "", completion: @escaping (Bool, String?) -> Void) {
            guard let url = URL(string: "\(APIConfig.baseURL)/api/portal/flag_portal") else {
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
                "portal_id": portalId,
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
}

struct PortalGoalsResponse: Codable {
    let aGoals: [Goal]
}

// MARK: - Portal Page

struct PortalPage: View {
    @StateObject private var viewModel = PortalViewModel()
    let portalId: Int
    let userId: Int
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode

    @State private var showFlagConfirmation = false
    @State private var flagResultMessage: String? = nil
    @State private var showFlagResultAlert = false
    @State private var selectedLead: User? = nil

    // Navigation/modal state
    @State private var navigateToEditAfterDismiss = false

    // Support state
    @State private var showPaymentSheet = false
    @State private var supportGoal: Goal? = nil

    // RSVP state
    @State private var rsvpResultMessage: String? = nil
    @State private var showRSVPResultAlert = false
    @State private var attendeesGoal: Goal? = nil
    @State private var isEventRegistered = false

    // Join Supporters state
    @State private var joinSupportersResultMessage: String? = nil
    @State private var showJoinSupportersResultAlert = false
    @State private var supportersGoal: Goal? = nil

    // Enum for all possible sheets (EditGoal, PortalActionSheet, GoalPicker)
    enum ActiveSheet: Identifiable {
        case addGoal
        case portalActionMenu
        case goalPicker

        var id: Int {
            switch self {
            case .addGoal: return 1
            case .portalActionMenu: return 2
            case .goalPicker: return 3
            }
        }
    }
    @State private var activeSheet: ActiveSheet?

    // Navigation state for EditPortal
    @State private var showEditPortal = false

    @State private var chatUserId: Int? = nil
    @State private var chatUserName: String = ""
    @State private var chatUserPhotoURL: URL? = nil
    @State private var showMessageSheet = false

    // Goal picker navigation state
    @State private var selectedGoal: Goal? = nil
    @State private var navigateToGoalDetails = false

    // Crash Prevention Guard
    @State private var hasAppeared = false

    // Device type check for robust sheet/fullScreenCover logic
    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private func leadRepUser(from portal: PortalDetail) -> User? {
        // Find the portal creator from aUsers using users_id
        guard let creatorId = portal.users_id else { return nil }
        return portal.aUsers?.first { $0.id == creatorId }
    }
    private func isCurrentUserLead(_ portal: PortalDetail) -> Bool {
        portal.aUsers?.contains(where: { $0.id == userId }) ?? false
    }

    private func findSupportableGoal(from goals: [Goal]) -> Goal? {
        return goals.first { $0.typeName == "Fund" || $0.typeName == "Sales" || $0.typeName == "Donations" }
    }

    private func findAttendeesGoal(from goals: [Goal]) -> Goal? {
        return goals.first {
            $0.typeName == "Recruiting" &&
            ($0.title.lowercased() == "attendees" || $0.title.lowercased().contains("attendee"))
        }
    }

    private func findSupportersGoal(from goals: [Goal]) -> Goal? {
        return goals.first {
            $0.typeName == "Recruiting" &&
            ($0.title.lowercased() == "supporters" || $0.title.lowercased().contains("supporter"))
        }
    }

    @AppStorage("jwtToken") private var jwtToken: String = ""

    // Join goal team function
    private func joinGoalTeam(goalId: Int, completion: ((Bool, String?) -> Void)? = nil) {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/goals/join_leave"),
              !jwtToken.isEmpty else {
            completion?(false, "Authentication required")
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
                   let result = json["result"] as? [String: Any] {
                    let status = result["\(goalId)"] as? String
                    if status == "ok" || status == "Already a member" {
                        // Success - refresh portal goals
                        self.viewModel.fetchPortalGoals(portalId: self.portalId)
                        completion?(true, nil)
                    } else {
                        print("Error joining goal team")
                        completion?(false, "Failed to register")
                    }
                } else {
                    print("Error joining goal team")
                    completion?(false, "Failed to register")
                }
            }
        }.resume()
    }

    // RSVP handler
    private func handleRSVP() {
        guard let goal = attendeesGoal else { return }

        joinGoalTeam(goalId: goal.id) { success, errorMessage in
            if success {
                isEventRegistered = true
                rsvpResultMessage = "✓ You're registered for this event!"
                showRSVPResultAlert = true
            } else {
                rsvpResultMessage = errorMessage ?? "Failed to register. Please try again."
                showRSVPResultAlert = true
            }
        }
    }

    // Join Supporters handler
    private func handleJoinSupporters() {
        guard let goal = supportersGoal else { return }

        joinGoalTeam(goalId: goal.id) { success, errorMessage in
            if success {
                joinSupportersResultMessage = "✓ You've joined the Supporters team!"
                showJoinSupportersResultAlert = true
            } else {
                joinSupportersResultMessage = errorMessage ?? "Failed to join. Please try again."
                showJoinSupportersResultAlert = true
            }
        }
    }

    // Helper for sheet content
    @ViewBuilder
    private func activeSheetView(portal: PortalDetail) -> some View {
        switch activeSheet {
        case .addGoal:
            EditGoalPage(
                existingGoal: nil,
                portalId: portal.id,
                userId: userId,
                reportingIncrements: viewModel.reportingIncrements,
                associatedPortalName: portal.name
            )
        case .portalActionMenu:
            VStack(spacing: 24) {
                // "$ Support" button always shown at the top, in dark green
                if supportGoal != nil {
                    Button(action: {
                        showPaymentSheet = true
                        activeSheet = nil // Dismiss the action menu before showing payment sheet
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(Color(UIColor(red: 0.0, green: 0.4, blue: 0.0, alpha: 1.0)))
                            Text("Support")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color(UIColor(red: 0.0, green: 0.4, blue: 0.0, alpha: 1.0)))
                        }
                        .padding(.vertical, 5)
                    }
                }

                if isCurrentUserLead(portal) {
                    Button(action: {
                        activeSheet = .addGoal
                    }) {
                        Text("Add Goal")
                            .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.vertical, 5)
                    }
                }
                Button(action: {
                    activeSheet = .goalPicker
                }) {
                    Text("Join Team")
                        .foregroundColor(Color(UIColor(red: 0.0, green: 0.4, blue: 0.0, alpha: 1.0)))
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.vertical, 5)
                }
                // Share button (available to everyone)
                ShareLink(
                    item: URL(string: "https://www.repsomething.com/portal/\(portal.id)")!,
                    subject: Text(portal.name),
                    message: Text("Check out \(portal.name) on Rep")
                ) {
                    Text("Share")
                        .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.vertical, 5)
                }
                if portal.users_id == userId {
                    Button(action: {
                        navigateToEditAfterDismiss = true
                        activeSheet = nil
                    }) {
                        Text("Edit Purpose")
                            .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.vertical, 5)
                    }
                }
                Button(action: {
                    showFlagConfirmation = true
                }) {
                    Text("Flag as Inappropriate")
                        .foregroundColor(.red)
                        .font(.body)
                        .padding(.vertical, 5)
                }
                .alert("Flag Portal?", isPresented: $showFlagConfirmation) {
                    Button("Flag", role: .destructive) {
                        viewModel.flagPortal(portalId: portal.id) { success, message in
                            flagResultMessage = success ? "Portal flagged. Thank you for your report." : (message ?? "Failed to flag portal.")
                            showFlagResultAlert = true
                        }
                        activeSheet = nil
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Are you sure you want to flag this portal as inappropriate?")
                }
                Button(action: { activeSheet = nil }) {
                    Text("Cancel")
                        .foregroundColor(.secondary)
                        .font(.body)
                }
            }
            .padding()
            .presentationDetents([.medium])
        case .goalPicker:
            GoalPickerSheet(
                goals: viewModel.portalGoals.filter { $0.typeName == "Recruiting" },
                currentUserId: userId,
                onJoin: { goalId in
                    joinGoalTeam(goalId: goalId)
                    activeSheet = nil
                },
                onViewDetails: { goal in
                    // Navigate to GoalsDetailView
                    selectedGoal = goal
                    navigateToGoalDetails = true
                    activeSheet = nil
                },
                onCancel: {
                    activeSheet = .portalActionMenu  // Back to main menu
                }
            )
        case .none:
            EmptyView()
        }
    }

    // Helper for main content
    @ViewBuilder
    private func mainContent() -> some View {
        if let portal = viewModel.portalDetail {
            PortalPageContent(
                portal: portal,
                viewModel: viewModel,
                dismiss: dismiss,
                userId: userId,
                leadRepUser: { leadRepUser(from: portal) },
                isCurrentUserLead: isCurrentUserLead(portal),
                attendeesGoal: attendeesGoal,
                supportersGoal: supportersGoal,
                isEventRegistered: isEventRegistered,
                onAdd: { activeSheet = .portalActionMenu },
                onMessage: {
                    if let lead = leadRepUser(from: portal) {
                        selectedLead = lead
                        showMessageSheet = true
                    } else {
                        print("No lead user found for portal!")
                    }
                },
                onRSVP: handleRSVP,
                onJoinSupporters: handleJoinSupporters
            )
            .onAppear {
                viewModel.fetchPortalGoals(portalId: portalId)
                if viewModel.reportingIncrements.isEmpty {
                    viewModel.fetchReportingIncrements()
                }
                NotificationCenter.default.addObserver(forName: .init("ShowEditPortalFromToolbar"), object: nil, queue: .main) { _ in
                    showEditPortal = true
                }
                hasAppeared = true
            }
            .disabled(!hasAppeared)
            .onChange(of: viewModel.portalGoals) { newGoals in
                supportGoal = findSupportableGoal(from: newGoals)
                attendeesGoal = findAttendeesGoal(from: newGoals)
                supportersGoal = findSupportersGoal(from: newGoals)
                if attendeesGoal?.is_member == true {
                    isEventRegistered = true
                }
            }
            .onDisappear {
                // Remove NotificationCenter observer
                NotificationCenter.default.removeObserver(self, name: .init("ShowEditPortalFromToolbar"), object: nil)
            }
            .navigationDestination(isPresented: $showEditPortal) {
                EditPortalView(portal: portal, userId: userId)
                    .interactiveDismissDisabled()
                    .onDisappear {
                        viewModel.fetchPortalDetail(portalId: portal.id, userId: userId)
                    }
            }
            .navigationDestination(isPresented: $navigateToGoalDetails) {
                if let goal = selectedGoal {
                    GoalsDetailView(initialGoal: goal)
                }
            }
            .sheet(item: $activeSheet, onDismiss: {
                if navigateToEditAfterDismiss {
                    showEditPortal = true
                    navigateToEditAfterDismiss = false // Reset flag
                }
            }) { sheetType in
                if let portal = viewModel.portalDetail {
                    activeSheetView(portal: portal)
                }
            }
            .sheet(isPresented: $showMessageSheet) {
                if let lead = selectedLead {
                    MessageView(
                        viewModel: MessageViewModel(
                            currentUserId: userId,
                            otherUserId: lead.id,
                            otherUserName: (lead.fname ?? "") + " " + (lead.lname ?? ""),
                            otherUserPhotoURL: lead.profilePictureURL
                        )
                    )
                    .presentationDetents([.large])
                }
            }
            .sheet(isPresented: $showPaymentSheet) {
                if let goal = supportGoal {
                    PayTransactionView(
                        portalId: portalId,
                        portalName: viewModel.portalDetail?.name ?? "Portal",
                        goalId: goal.id,
                        goalName: goal.title,
                        // "Donations" type goals trigger disclosure workflow and open in Safari
                        // "Fund" and "Sales" goals use regular payment workflow without disclosure
                        transactionType: goal.typeName == "Donations" ? .donation : .payment
                    )
                    .presentationDetents([.large])
                }
            }
        } else {
            ProgressView()
                .onAppear {
                    viewModel.fetchPortalDetail(portalId: portalId, userId: userId)
                    hasAppeared = true
                }
        }
    }

    var body: some View {
        NavigationStack {
            mainContent()
                .navigationBarBackButtonHidden(true)
                .navigationBarHidden(true)
                .alert(flagResultMessage ?? "", isPresented: $showFlagResultAlert) {
                    Button("OK", role: .cancel) { flagResultMessage = nil }
                }
                .alert(rsvpResultMessage ?? "", isPresented: $showRSVPResultAlert) {
                    Button("OK", role: .cancel) { rsvpResultMessage = nil }
                }
                .alert(joinSupportersResultMessage ?? "", isPresented: $showJoinSupportersResultAlert) {
                    Button("OK", role: .cancel) { joinSupportersResultMessage = nil }
                }
        }
    }
}

// MARK: - Goal Picker Sheet

struct GoalPickerSheet: View {
    let goals: [Goal]
    let currentUserId: Int
    let onJoin: (Int) -> Void
    let onViewDetails: (Goal) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onCancel) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                        Text("Back")
                            .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                    }
                }
                Spacer()
                Text("Join Team")
                    .font(.headline)
                Spacer()
                // Spacer for symmetry
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                }
            }
            .padding()

            Divider()

            // Goal List
            ScrollView {
                if goals.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.5))
                            .padding(.top, 40)
                        Text("No Goal Teams Available")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Check back later for new opportunities")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    VStack(spacing: 0) {
                        ForEach(goals) { goal in
                            GoalPickerRow(
                                goal: goal,
                                currentUserId: currentUserId,
                                onJoin: { onJoin(goal.id) },
                                onViewDetails: { onViewDetails(goal) }
                            )
                            Divider()
                        }
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

struct GoalPickerRow: View {
    let goal: Goal
    let currentUserId: Int
    let onJoin: () -> Void
    let onViewDetails: () -> Void

    // For now, we'll use a simplified check - in the future, you can pass team member data
    // to properly check if user is already on team
    private var isCreator: Bool {
        goal.creatorId == currentUserId
    }

    // Compute tag text (matching GoalListItem logic)
    private var tagText: String {
        if goal.typeName.lowercased() == "other" {
            let raw = goal.metricName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !raw.isEmpty else { return goal.typeName }
            return String(raw.prefix(9))
        } else {
            return goal.typeName
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Bar Chart (matching GoalListItem) - tappable to view details
            Button(action: onViewDetails) {
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(goal.chartData.suffix(4)) { bar in
                        let quota = goal.quota > 0 ? goal.quota : 1
                        let barHeight = max(0, min(1.0, CGFloat(bar.value / quota)) * 77)
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            Rectangle()
                                .fill(Color.repGreen)
                                .frame(width: 24, height: barHeight)
                                .cornerRadius(3)
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: 4 * 24 + 3 * 6, height: 81, alignment: .leading)
            .padding(.vertical, 4)

            // Title, subtitle, progress (matching GoalListItem) - tappable to view details
            Button(action: onViewDetails) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(goal.title)
                            .font(.headline)
                            .foregroundColor(Color(UIColor(red: 0.0, green: 0.4, blue: 0.0, alpha: 1.0)))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(UIColor(red: 0.0, green: 0.4, blue: 0.0, alpha: 1.0)))
                    }
                    if !goal.subtitle.isEmpty {
                        Text(goal.subtitle)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    Text("\(Int(goal.progressPercent))% [\(tagText)]")
                        .font(.callout)
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(PlainButtonStyle())

            // Action button - independent, NOT nested
            VStack(spacing: 4) {
                if !isCreator {
                    Button(action: onJoin) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 16))
                            Text("Join")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.repGreen)
                        .cornerRadius(8)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                        Text("Creator")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(Color.repGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.repGreen.opacity(0.1))
                    .cornerRadius(6)
                }
            }
        }
        .frame(height: 81)
        .padding(.vertical, 4)
        .padding(.horizontal)
        .background(Color.white)
    }
}

// MARK: - PortalPageContent

struct PortalPageContent: View {
    let portal: PortalDetail
    @ObservedObject var viewModel: PortalViewModel
    let dismiss: DismissAction
    let userId: Int
    let leadRepUser: () -> User?
    let isCurrentUserLead: Bool
    let attendeesGoal: Goal?
    let supportersGoal: Goal?
    let isEventRegistered: Bool
    let onAdd: () -> Void
    let onMessage: () -> Void
    let onRSVP: () -> Void
    let onJoinSupporters: () -> Void

    @State private var showFullscreen = false
    @State private var fullscreenIndex = 0
    @State private var showCalendarPicker = false
    @StateObject private var orientationObserver = OrientationObserver()

    private var imageTabHeight: CGFloat {
        UIScreen.main.bounds.width * 9 / 16
    }

    private func calendarGoogleUrl() -> URL? {
        guard let dt = portal.event_datetime else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        var parsed = formatter.date(from: dt)
        if parsed == nil {
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
            parsed = formatter.date(from: dt)
        }
        guard let start = parsed else { return nil }
        let end = start.addingTimeInterval(3600)
        let fmt = { (d: Date) -> String in
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.dateFormat = "yyyyMMdd'T'HHmmss"
            return f.string(from: d)
        }
        var parts = [
            "action=TEMPLATE",
            "text=\(portal.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")",
            "dates=\(fmt(start))/\(fmt(end))",
        ]
        if let loc = portal.event_location, !loc.isEmpty {
            parts.append("location=\(loc.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        }
        if let about = portal.about, !about.isEmpty {
            let snippet = String(about.prefix(200))
            parts.append("details=\(snippet.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        }
        return URL(string: "https://calendar.google.com/calendar/render?" + parts.joined(separator: "&"))
    }

    private func calendarIcsUrl() -> URL? {
        URL(string: "https://rep-june2025.onrender.com/api/portal/\(portal.id)/calendar.ics")
    }


    // Sticky header as a computed property to help the compiler
    private var stickyHeader: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 4)
            Rectangle()
                .fill(Color(UIColor(red: 0.894, green: 0.894, blue: 0.894, alpha: 1.0)))
                .frame(height: 1)
                .padding(.horizontal, 0)
            PortalSegmentedPicker(
                segments: ["Goal Teams", "Story"],
                selectedIndex: $viewModel.section
            )
            .padding(.horizontal)
            .background(Color.white)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            PortalHeader(portal: portal, dismiss: dismiss)
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    GeometryReader { geometry in
                        let width = geometry.size.width
                        let mainSections = (portal.aSections ?? []).filter { $0.title == "Main Section" }
                        ImageTabView(sections: mainSections)
                            .frame(width: width, height: imageTabHeight)
                            .clipped()
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showFullscreen = true
                                fullscreenIndex = 0
                            }
                    }
                    .frame(height: imageTabHeight)
                    .fullScreenCover(isPresented: $showFullscreen) {
                        let mainImages = (portal.aSections ?? []).filter { $0.title == "Main Section" }.flatMap { $0.aFiles }
                        FullscreenImageViewer(
                            images: mainImages,
                            startIndex: fullscreenIndex,
                            onDismiss: { showFullscreen = false }
                        )
                        .ignoresSafeArea()
                    }
                    .onAppear {
                        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
                    }
                    .onDisappear {
                        UIDevice.current.endGeneratingDeviceOrientationNotifications()
                    }
                    .onChange(of: orientationObserver.isLandscape) { isLandscape in
                        if isLandscape && !showFullscreen {
                            showFullscreen = true
                            fullscreenIndex = 0
                        }
                    }
                    .onAppear {
                        print("Portal aLeads:", portal.aLeads?.map { $0.id } ?? [])
                        // Preload lead profile images immediately for faster Story tab display
                        let leadImageURLs = (portal.aLeads ?? []).compactMap { $0.profilePictureURL }
                        if !leadImageURLs.isEmpty {
                            let imagePrefetcher = ImagePrefetcher(urls: leadImageURLs)
                            imagePrefetcher.start()
                        }
                    }
                    // Sticky segmented picker
                    Section(header: stickyHeader) {
                        PortalSectionContent(
                            viewModel: viewModel,
                            portal: portal,
                            section: viewModel.section
                        )
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                }
            }
            Spacer()
            BottomBarView(
                onAdd: onAdd,
                onMessage: onMessage
            )
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 0) {
                // Join Supporters Button (only show if Supporters goal exists and no Attendees goal)
                if supportersGoal != nil && attendeesGoal == nil {
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color(UIColor(red: 0.894, green: 0.894, blue: 0.894, alpha: 1.0)))
                            .frame(height: 1)
                        Button(action: onJoinSupporters) {
                            Text("Join Supporters")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color(UIColor(red: 0.482, green: 0.749, blue: 0.294, alpha: 1.0)))
                                .cornerRadius(6)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .background(Color.white)
                }

                // Add to Calendar buttons (only after user registers for event)
                if isEventRegistered && portal.event_datetime != nil {
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color(UIColor(red: 0.894, green: 0.894, blue: 0.894, alpha: 1.0)))
                            .frame(height: 1)
                        Button(action: { showCalendarPicker = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar.badge.plus")
                                Text("Add to Calendar")
                                    .fontWeight(.bold)
                            }
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color(UIColor(red: 0.0, green: 0.4, blue: 0.0, alpha: 1.0)))
                            .cornerRadius(6)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .confirmationDialog("Add to Calendar", isPresented: $showCalendarPicker, titleVisibility: .visible) {
                            if let gcUrl = calendarGoogleUrl() {
                                Button("Google Calendar") { UIApplication.shared.open(gcUrl) }
                            }
                            if let icsUrl = calendarIcsUrl() {
                                Button("Apple Calendar") { UIApplication.shared.open(icsUrl) }
                                Button("Microsoft / Outlook") { UIApplication.shared.open(icsUrl) }
                            }
                            Button("Cancel", role: .cancel) { }
                        }
                    }
                    .background(Color.white)
                }

                // Register Button (only show if Attendees goal exists and not yet registered)
                if attendeesGoal != nil && !isEventRegistered {
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color(UIColor(red: 0.894, green: 0.894, blue: 0.894, alpha: 1.0)))
                            .frame(height: 1)
                        Button(action: onRSVP) {
                            Text("Register for Event")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color(UIColor(red: 0.482, green: 0.749, blue: 0.294, alpha: 1.0)))
                                .cornerRadius(6)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .background(Color.white)
                }
            }
            .padding(.bottom, 56)
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
        .navigationBarHidden(true)
        .navigationTitle(portal.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Join Team") { onAdd() }
                    Button("Edit Portal") {
                        // Use direct navigation trigger
                        NotificationCenter.default.post(name: .init("ShowEditPortalFromToolbar"), object: nil)
                    }
                    ShareLink(
                        item: URL(string: "https://www.repsomething.com/portal/\(portal.id)")!,
                        subject: Text(portal.name),
                        message: Text("Check out \(portal.name) on Rep")
                    ) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
    }
}

// MARK: - Fullscreen Image Viewer

struct FullscreenImageViewer: View {
    let images: [PortalFile]
    let startIndex: Int
    let onDismiss: () -> Void

    @State private var selectedIndex: Int

    init(images: [PortalFile], startIndex: Int, onDismiss: @escaping () -> Void) {
        self.images = images
        self.startIndex = startIndex
        self.onDismiss = onDismiss
        _selectedIndex = State(initialValue: startIndex)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            TabView(selection: $selectedIndex) {
                ForEach(Array(images.enumerated()), id: \.offset) { idx, file in
                    if let urlString = file.url, let url = URL(string: urlString) {
                        ZoomableAsyncImage(url: url)
                            .tag(idx)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(Text("No Image").foregroundColor(.secondary))
                            .tag(idx)
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            .ignoresSafeArea()
            Button(action: { onDismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .padding(.top, 40)
                    .padding(.trailing, 40)
                    .contentShape(Rectangle()) // Ensures the tap area is reliable
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - ZoomableAsyncImage

struct ZoomableAsyncImage: View {
    let url: URL

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = min(max(1.0, lastScale * value), 5.0)
                                }
                                .onEnded { value in
                                    scale = min(max(1.0, lastScale * value), 5.0)
                                    lastScale = scale
                                }
                        )
                        // Only enable drag/pan when zoomed in
                        .gesture(
                            scale > 1.01 ?
                                DragGesture()
                                    .onChanged { value in
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                    }
                                : nil
                        )
                        .gesture(
                            TapGesture(count: 2)
                                .onEnded {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        if scale > 1.01 {
                                            scale = 1.0
                                            lastScale = 1.0
                                            offset = .zero
                                            lastOffset = .zero
                                        } else {
                                            scale = 2.5
                                            lastScale = 2.5
                                        }
                                    }
                                }
                        )
                        .animation(.easeInOut(duration: 0.15), value: scale)
                        .animation(.easeInOut(duration: 0.15), value: offset)
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height
                        )
                        .background(Color.black)
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
        }
        .ignoresSafeArea()
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
                    .frame(width: 44, height: 44) 
                    .contentShape(Rectangle()) 
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
    @ObservedObject var viewModel: PortalViewModel
    let portal: PortalDetail
    let section: Int

    var body: some View {
        Group {
            if section == 0 {
                // "Goal Teams" tab
                PortalResultsSection(goals: viewModel.portalGoals)
            } else if section == 1 {
                // "Story" tab
                PortalStorySection(portal: portal)
            }
        }
    }
}

// MARK: - Image Tab View

struct ImageTabView: View {
    let sections: [PortalSection]

    @State private var currentIndex: Int = 0

    private var images: [PortalFile] {
        sections.flatMap { $0.aFiles }
    }

    var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(Array(images.enumerated()), id: \.offset) { index, file in
                Group {
                    if let urlString = file.url, let url = URL(string: urlString) {
                        KFImage(url)
                            .resizable()
                            .scaledToFill()
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(Text("No Image").foregroundColor(.secondary))
                    }
                }
                .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle())
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        .task {
            await runIntroSlideshow()
        }
    }

    @MainActor
    private func runIntroSlideshow() async {
        guard images.count > 1 else { return }

        // Preload first 4 images into Kingfisher cache before starting (skips any already cached)
        let urls = images.prefix(4).compactMap { URL(string: $0.url ?? "") }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            ImagePrefetcher(urls: urls) { _, _, _ in
                continuation.resume()
            }.start()
        }
        guard !Task.isCancelled else { return }

        for i in 1..<images.count {
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.none) { currentIndex = i }
        }
        try? await Task.sleep(nanoseconds: 250_000_000)
        guard !Task.isCancelled else { return }
        withAnimation(.none) { currentIndex = 0 }
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

struct GalleryFullscreenItem: Identifiable {
    let id = UUID()
    let sectionId: Int
    let startIndex: Int
}

struct PortalStorySection: View {
    let portal: PortalDetail
    @State private var galleryFullscreen: GalleryFullscreenItem? = nil

    private func googleCalUrl() -> URL? {
        guard let dt = portal.event_datetime,
              let parsed = parsedEventDate(dt) else { return nil }
        let end = parsed.addingTimeInterval(3600)
        let fmt = { (d: Date) -> String in
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.dateFormat = "yyyyMMdd'T'HHmmss"
            return f.string(from: d)
        }
        var parts = [
            "action=TEMPLATE",
            "text=\(portal.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")",
            "dates=\(fmt(parsed))/\(fmt(end))",
        ]
        if let loc = portal.event_location, !loc.isEmpty {
            parts.append("location=\(loc.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        }
        if let about = portal.about, !about.isEmpty {
            let snippet = String(about.prefix(200))
            parts.append("details=\(snippet.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        }
        let urlString = "https://calendar.google.com/calendar/render?" + parts.joined(separator: "&")
        return URL(string: urlString)
    }

    private func icsUrl() -> URL? {
        URL(string: "https://rep-june2025.onrender.com/api/portal/\(portal.id)/calendar.ics")
    }

    private func parsedEventDate(_ dtString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let d = formatter.date(from: dtString) { return d }
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return formatter.date(from: dtString)
    }

    private func formattedEventDate(_ dtString: String) -> String {
        guard let date = parsedEventDate(dtString) else { return dtString }
        let display = DateFormatter()
        display.dateStyle = .full
        display.timeStyle = .short
        return display.string(from: date)
    }

    // Preload lead images immediately when view is created
    private func preloadLeadImages() {
        let imagePrefetcher = ImagePrefetcher(urls: (portal.aLeads ?? []).compactMap { $0.profilePictureURL })
        imagePrefetcher.start()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Leads")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(portal.aLeads ?? []) { user in   // <-- Use aLeads here
                        VStack {
                            if let url = user.profilePictureURL {
                                KFImage(url)
                                    .placeholder {
                                        Circle().fill(Color.gray.opacity(0.3))
                                    }
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 28, height: 28)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 28, height: 28)
                            }
                            Text("\(user.fname?.prefix(1) ?? "")\(user.lname?.prefix(1) ?? "")")
                                .font(.caption2)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .onAppear {
                // Preload images when scroll view appears
                preloadLeadImages()
            }
            Divider()
            // Story Text Blocks with clickable links (sorted by position)
            ForEach((portal.aTexts ?? [])
                .filter { ($0.section ?? "") == "story" }
                .sorted { ($0.position ?? 0) < ($1.position ?? 0) },
                id: \.id
            ) { block in
                VStack(alignment: .leading, spacing: 4) {
                    if let title = block.title, !title.isEmpty {
                        Text(title)
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                    if let text = block.text, !text.isEmpty {
                        LinkableText(text: text, fontSize: 16)
                    }
                }
                .padding(.vertical, 4)
            }

            // Gallery Sections (non-Main Section images)
            let gallerySections = (portal.aSections ?? [])
                .filter { $0.title != "Main Section" && !$0.aFiles.isEmpty }
            ForEach(gallerySections) { section in
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .padding(.top, 4)
                    Text(section.title)
                        .font(.headline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(section.aFiles.enumerated()), id: \.element.id) { idx, file in
                                if let urlString = file.url, let url = URL(string: urlString) {
                                    KFImage(url)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 213, height: 120)
                                        .clipped()
                                        .cornerRadius(8)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            galleryFullscreen = GalleryFullscreenItem(sectionId: section.id, startIndex: idx)
                                        }
                                }
                            }
                        }
                    }
                }
            }

            // Event Details (only for event-type portals)
            if portal.portal_type == "event",
               portal.event_datetime != nil || portal.event_location != nil {
                Divider()
                    .padding(.top, 4)
                Text("Event Details")
                    .font(.headline)
                    .padding(.top, 2)
                if let dtString = portal.event_datetime {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "calendar")
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(formattedEventDate(dtString))
                                .font(.body)
                            if let tz = portal.event_timezone, !tz.isEmpty {
                                Text(tz)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                if let location = portal.event_location, !location.isEmpty {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        Text(location)
                            .font(.body)
                    }
                }

                // (Calendar buttons moved to floating overlay)
            }

            // Extra bottom padding to allow scrolling past bottom buttons
            Spacer()
                .frame(height: 130)
        }
        .fullScreenCover(item: $galleryFullscreen) { data in
            let sectionImages = (portal.aSections ?? [])
                .first(where: { $0.id == data.sectionId })?.aFiles ?? []
            FullscreenImageViewer(
                images: sectionImages,
                startIndex: data.startIndex,
                onDismiss: { galleryFullscreen = nil }
            )
            .ignoresSafeArea()
        }
    }
}

struct PortalResultsSection: View {
    let goals: [Goal]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(goals) { goal in
                VStack {
                    NavigationLink(destination: GoalsDetailView(initialGoal: goal)) {
                        GoalListItem(goal: goal)
                    }
                    .buttonStyle(PlainButtonStyle())
                    Divider()
                }
            }

            // Extra bottom padding to allow scrolling past floating buttons
            Spacer()
                .frame(height: 130)
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
    let portal_type: String?
    let event_datetime: String?
    let event_location: String?
    let event_timezone: String?
    let aGoals: [Goal]?
    let aPortalUsers: [PortalUser]?
    let aTexts: [PortalText]?
    let aSections: [PortalSection]?
    let aUsers: [User]?
    let aLeads: [User]?
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
    let position: Int?
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

struct LinkableText: View {
    let text: String
    let fontSize: CGFloat
    let openInApp: Bool

    init(text: String, fontSize: CGFloat = 16, openInApp: Bool = true) {
        self.text = text
        self.fontSize = fontSize
        self.openInApp = openInApp
    }

    var body: some View {
        Text(attributedString)
            .font(.system(size: fontSize))
            .onTapGesture {
                if let url = firstURL {
                    UIApplication.shared.open(url)
                }
            }
    }

    private var attributedString: AttributedString {
        var attributedString = AttributedString(text)
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        matches?.forEach { match in
            if let range = Range(match.range, in: text), let url = match.url {
                let linkRange = attributedString.range(of: String(text[range]))
                if let linkRange = linkRange {
                    attributedString[linkRange].foregroundColor = .blue
                    attributedString[linkRange].underlineStyle = .single
                }
            }
        }
        return attributedString
    }

    private var firstURL: URL? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        return matches?.first?.url
    }
}
