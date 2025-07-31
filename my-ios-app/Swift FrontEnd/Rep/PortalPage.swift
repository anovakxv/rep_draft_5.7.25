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

    func fetchPortalGoals(portalId: Int) {
        let urlString = "\(APIConfig.baseURL)/api/goals/portal?portals_id=\(portalId)"
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data else { return }
            do {
                let response = try JSONDecoder().decode(PortalGoalsResponse.self, from: data)
                DispatchQueue.main.async {
                    self.portalGoals = response.aGoals
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

    @State private var showFlagConfirmation = false
    @State private var flagResultMessage: String? = nil
    @State private var showFlagResultAlert = false

    // Navigation/modal state
    @State private var pendingAction: PendingAction? = nil

    // Enum for all possible sheets (EditGoal, Message, PortalActionSheet)
    enum ActiveSheet: Identifiable {
        case addGoal
        case message
        case portalActionMenu

        var id: Int {
            switch self {
            case .addGoal: return 1
            case .message: return 2
            case .portalActionMenu: return 3
            }
        }
    }
    @State private var activeSheet: ActiveSheet?

    // NavigationLink for EditPortal
    @State private var showEditPortal = false

    @State private var selectedGoalId: Int? = nil
    @State private var chatUserId: Int? = nil
    @State private var chatUserName: String = ""
    @State private var chatUserPhotoURL: URL? = nil

    private func leadRepUser(from portal: PortalDetail) -> User? {
        return portal.aUsers?.first
    }
    private func isCurrentUserLead(_ portal: PortalDetail) -> Bool {
        portal.aUsers?.contains(where: { $0.id == userId }) ?? false
    }

    enum PendingAction: Equatable {
        case addGoal
        case editPortal
        case joinTeam
        case message(User)
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
        case .message:
            if let lead = leadRepUser(from: portal) {
                MessageView(
                    viewModel: MessageViewModel(
                        currentUserId: userId,
                        otherUserId: lead.id,
                        otherUserName: "\(lead.fname ?? "") \(lead.lname ?? "")",
                        otherUserPhotoURL: lead.profilePictureURL
                    )
                )
            } else {
                Text("Lead Rep not found.")
            }
        case .portalActionMenu:
            VStack(spacing: 24) {
                if isCurrentUserLead(portal) {
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
                }
                Button(action: {
                    pendingAction = .joinTeam
                    activeSheet = nil
                }) {
                    Text("Select Goal Team")
                        .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.vertical, 5)
                }
                if portal.users_id == userId {
                    Button(action: {
                        pendingAction = .editPortal
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
                        .fontWeight(.bold)
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
                selectedGoalId: $selectedGoalId,
                userId: userId,
                leadRepUser: { leadRepUser(from: portal) },
                isCurrentUserLead: isCurrentUserLead(portal),
                onAdd: { activeSheet = .portalActionMenu },
                onMessage: {
                    if let lead = leadRepUser(from: portal) {
                        chatUserId = lead.id
                        chatUserName = (lead.fname ?? "") + " " + (lead.lname ?? "")
                        chatUserPhotoURL = lead.profilePictureURL
                        activeSheet = .message
                    }
                }
            )
            .sheet(item: $activeSheet) { _ in
                activeSheetView(portal: portal)
            }
            // NavigationLink for EditPortalView
            NavigationLink(
                destination: EditPortalView(portal: portal, userId: userId)
                    .interactiveDismissDisabled()
                    .onDisappear {
                        viewModel.fetchPortalDetail(portalId: portal.id, userId: userId)
                    },
                isActive: $showEditPortal
            ) {
                EmptyView()
            }
            .hidden()
            .onAppear {
                viewModel.fetchPortalGoals(portalId: portalId)
                if viewModel.reportingIncrements.isEmpty {
                    viewModel.fetchReportingIncrements()
                }
            }
            .onChange(of: pendingAction) { action in
                guard let action = action else { return }
                switch action {
                case .addGoal:
                    activeSheet = .addGoal
                case .editPortal:
                    showEditPortal = true
                case .joinTeam:
                    // Implement join team logic here if needed
                    break
                case .message(let user):
                    chatUserId = user.id
                    chatUserName = (user.fname ?? "") + " " + (user.lname ?? "")
                    chatUserPhotoURL = user.profilePictureURL
                    activeSheet = .message
                }
                pendingAction = nil
            }
        } else {
            ProgressView()
                .onAppear {
                    viewModel.fetchPortalDetail(portalId: portalId, userId: userId)
                }
        }
    }

    var body: some View {
        NavigationStack {
            mainContent()
                .background(
                    NavigationLink(
                        destination: selectedGoalId.flatMap { goalId in
                            viewModel.portalGoals.first(where: { $0.id == goalId }).map { GoalsDetailView(initialGoal: $0) }
                        },
                        isActive: Binding(
                            get: { selectedGoalId != nil },
                            set: { isActive in if !isActive { selectedGoalId = nil } }
                        ),
                        label: { EmptyView() }
                    )
                    .hidden()
                )
                .navigationBarHidden(true)
                .alert(flagResultMessage ?? "", isPresented: $showFlagResultAlert) {
                Button("OK", role: .cancel) { flagResultMessage = nil }
            }
        }
    }
}

// MARK: - PortalPageContent

struct PortalPageContent: View {
    let portal: PortalDetail
    @ObservedObject var viewModel: PortalViewModel
    let dismiss: DismissAction
    @Binding var selectedGoalId: Int?
    let userId: Int
    let leadRepUser: () -> User?
    let isCurrentUserLead: Bool
    let onAdd: () -> Void
    let onMessage: () -> Void

    @State private var showFullscreen = false
    @State private var fullscreenIndex = 0
    @StateObject private var orientationObserver = OrientationObserver()

    private var imageTabHeight: CGFloat {
        UIScreen.main.bounds.width * 9 / 16
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
                        let images = (portal.aSections ?? []).flatMap { $0.aFiles }
                        ImageTabView(sections: portal.aSections ?? [])
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
                        let images = (portal.aSections ?? []).flatMap { $0.aFiles }
                        FullscreenImageViewer(
                            images: images,
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
                    }
                    // Sticky segmented picker
                    Section(header: stickyHeader) {
                        PortalSectionContent(
                            viewModel: viewModel,
                            portal: portal,
                            section: viewModel.section,
                            selectedGoalId: $selectedGoalId
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
        .background(Color.white.edgesIgnoringSafeArea(.all))
        .navigationBarHidden(true)
        .navigationTitle(portal.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Join Team") { onAdd() }
                    Button("Edit Portal") { 
                        // Use parent navigation logic
                        NotificationCenter.default.post(name: .init("ShowEditPortalFromToolbar"), object: nil)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
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
    @Binding var selectedGoalId: Int?

    var body: some View {
        Group {
            if section == 0 {
                // "Goal Teams" tab
                PortalResultsSection(goals: viewModel.portalGoals, selectedGoalId: $selectedGoalId)
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

    var body: some View {
        TabView {
            ForEach(sections.flatMap { $0.aFiles }) { file in
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
        }
        .tabViewStyle(PageTabViewStyle())
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
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
                    ForEach(portal.aLeads ?? []) { user in   // <-- Use aLeads here
                        VStack {
                            if let url = user.profilePictureURL {
                                AsyncImage(url: url) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Circle().fill(Color.gray.opacity(0.3))
                                }
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
            Divider()
            // Show Story Text Blocks
            ForEach((portal.aTexts ?? []).filter { ($0.section ?? "") == "story" }) { block in
                VStack(alignment: .leading, spacing: 4) {
                    if let title = block.title, !title.isEmpty {
                        Text(title)
                            .font(.title3)
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