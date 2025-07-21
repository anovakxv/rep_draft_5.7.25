//  PortalPage.swift
//  Rep
//
//  Created by Dmytro Holovko on 10.28.2023.
//  Updated by Adam Novak on 07.20.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.

import SwiftUI
import _PhotosUI_SwiftUI
import Combine

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

struct PortalGoalsResponse: Codable {
    let aGoals: [Goal]
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
                        viewModel.fetchPortalGoals(portalId: portalId)
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

    // Fullscreen image viewer state
    @State private var showFullscreen = false
    @State private var fullscreenIndex = 0

    @StateObject private var orientationObserver = OrientationObserver()

    enum PortalActionSheetAction {
        case joinTeam
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
               let selectedGoal = viewModel.portalGoals.first(where: { $0.id == goalId }) {
                GoalsDetailView(initialGoal: selectedGoal)
            } else {
                EmptyView()
            }
        }
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

                    // --- DEBUG: Print aLeads on load ---
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
                    Text("Select Goal Team")
                        .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.vertical, 5)
                }
                // Only show "Edit Purpose" if the current user is the creator
                if portal.users_id == userId {
                    Button(action: {
                        pendingPortalAction = .editPortal
                        showPortalActionSheet = false
                    }) {
                        Text("Edit Purpose")
                            .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.vertical, 5)
                    }
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
                    .font(.system(size: 36))
                    .foregroundColor(.white)
                    .padding()
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
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = min(max(1.0, lastScale * value), 5.0)
                                    }
                                    .onEnded { value in
                                        scale = min(max(1.0, lastScale * value), 5.0)
                                        lastScale = scale
                                    },
                                SimultaneousGesture(
                                    DragGesture()
                                        .onChanged { value in
                                            offset = CGSize(
                                                width: lastOffset.width + value.translation.width,
                                                height: lastOffset.height + value.translation.height
                                            )
                                        }
                                        .onEnded { _ in
                                            lastOffset = offset
                                        },
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
                            )
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
        // Show all images in all sections as swipeable
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