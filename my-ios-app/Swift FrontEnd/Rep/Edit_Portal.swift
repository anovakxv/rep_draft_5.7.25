//
//  Edit_Portal.swift
//  Rep
//
//  Created by Adam Novak on 06.23.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

import SwiftUI
import PhotosUI

// MARK: - EditableGoal Model

struct EditableGoal: Identifiable {
    let id = UUID()
    var title: String
    var subtitle: String?
    var progressPercent: Double?
    var typeName: String?
    var chartData: [BarChartData]?

    init(goal: Goal) {
        self.title = goal.title
        self.subtitle = goal.subtitle
        self.progressPercent = goal.progressPercent
        self.typeName = goal.typeName
        self.chartData = goal.chartData
    }

    init(title: String, subtitle: String?, progressPercent: Double?, typeName: String?, chartData: [BarChartData]?) {
        self.title = title
        self.subtitle = subtitle
        self.progressPercent = progressPercent
        self.typeName = typeName
        self.chartData = chartData
    }
}

// MARK: - PortalWriteBlock Model

struct PortalWriteBlock: Identifiable, Codable {
    let id: UUID
    var title: String?
    var content: String
    var order: Int?
    var created_at: String?
    var updated_at: String?

    // NEW: Support for HTML content format (optional for backwards compatibility)
    var contentFormat: String?

    init(title: String?, content: String, order: Int? = nil) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.order = order
        self.contentFormat = "plain" // iOS always creates plain text writes
    }

    enum CodingKeys: String, CodingKey {
        case id, title, content, order, created_at, updated_at
        case contentFormat = "content_format"
    }
}

// MARK: - Portal Type + Timezone Constants

let portalTypeOptions: [(value: String, label: String)] = [
    ("", "General"),
    ("event", "Event"),
    ("nonprofit", "Nonprofit"),
    ("business", "Business"),
    ("initiative", "Initiative"),
    ("campaign", "Campaign"),
    ("community", "Community"),
]

let eventTimezoneOptions: [String] = [
    "America/New_York",
    "America/Chicago",
    "America/Denver",
    "America/Los_Angeles",
    "America/Anchorage",
    "Pacific/Honolulu",
    "America/Phoenix",
    "America/Toronto",
    "America/Vancouver",
    "America/Halifax",
    "Europe/London",
    "Europe/Paris",
    "Europe/Berlin",
    "Europe/Rome",
    "Europe/Amsterdam",
    "Europe/Madrid",
    "Europe/Stockholm",
    "Europe/Zurich",
    "Europe/Warsaw",
    "Europe/Athens",
    "Europe/Istanbul",
    "Asia/Dubai",
    "Asia/Kolkata",
    "Asia/Singapore",
    "Asia/Tokyo",
    "Asia/Seoul",
    "Asia/Shanghai",
    "Australia/Sydney",
    "Australia/Melbourne",
    "Pacific/Auckland",
    "UTC",
]

// MARK: - EditPortalViewModel

class EditPortalViewModel: ObservableObject {
    @Published var name: String
    @Published var subtitle: String
    @Published var about: String
    @Published var offeringText: String
    @Published var goals: [EditableGoal]
    @Published var selectedImages: [UIImage] = []
    @Published var mainImageIndex: Int = 0
    @Published var portalDetail: PortalDetail? // Added to pass to subviews

    // Portal type + event fields
    @Published var portalType: String = ""
    @Published var eventDatetime: Date = Date()
    @Published var eventLocation: String = ""
    @Published var eventTimezone: String = ""
    @Published var eventDurationMinutes: Int = 90

    // Story blocks
    @Published var storyBlocks: [PortalWriteBlock] = []

    // Add Leads
    @Published var selectedLeads: [User] = []

    let portalId: Int
    let userId: Int
    let maxImages = 10

    @AppStorage("jwtToken") var jwtToken: String = ""

    init(portal: PortalDetail, userId: Int) {
        self.portalDetail = portal // Added
        self.portalId = portal.id
        self.userId = userId
        self.name = portal.name
        self.subtitle = portal.subtitle ?? ""
        self.about = portal.about ?? ""
        self.offeringText = portal.about ?? ""
        self.goals = (portal.aGoals ?? []).map { EditableGoal(goal: $0) }
        // Only load story blocks (section == "story"), sorted by position
        self.storyBlocks = (portal.aTexts?
            .filter { $0.section == "story" }
            .sorted { ($0.position ?? 0) < ($1.position ?? 0) }
            .enumerated()
            .map { idx, text in
                PortalWriteBlock(title: text.title ?? "", content: text.text ?? "", order: idx)
            } ?? [])
        // Optionally prefill selectedLeads from portal.aUsers if needed

        // Portal type + event fields
        self.portalType = portal.portal_type ?? ""
        if let dtString = portal.event_datetime {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            if let parsed = formatter.date(from: dtString) {
                self.eventDatetime = parsed
            } else {
                // Try without seconds
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
                self.eventDatetime = formatter.date(from: dtString) ?? Date()
            }
        }
        self.eventLocation = portal.event_location ?? ""
        self.eventTimezone = portal.event_timezone ?? ""
        self.eventDurationMinutes = portal.event_duration_minutes ?? 90
    }

    func addGoal() {
        goals.append(EditableGoal(title: "", subtitle: "", progressPercent: nil, typeName: "", chartData: []))
    }

    func removeImage(at index: Int) {
        guard selectedImages.indices.contains(index) else { return }
        selectedImages.remove(at: index)
        if selectedImages.isEmpty {
            mainImageIndex = 0
        } else if mainImageIndex >= selectedImages.count {
            mainImageIndex = selectedImages.count - 1
        }
    }

    func loadImages(from items: [PhotosPickerItem]) {
        let currentCount = selectedImages.count
        let availableSlots = maxImages - currentCount
        let itemsToLoad = Array(items.prefix(availableSlots))
        var imagesToAdd = Array<UIImage?>(repeating: nil, count: itemsToLoad.count)
        let group = DispatchGroup()
        for (idx, item) in itemsToLoad.enumerated() {
            group.enter()
            item.loadTransferable(type: Data.self) { result in
                defer { group.leave() }
                switch result {
                case .success(let data):
                    if let data, let image = UIImage(data: data) {
                        imagesToAdd[idx] = image
                    }
                case .failure(let error):
                    print("Failed to load image: \(error)")
                }
            }
        }
        group.notify(queue: .main) {
            // Only append non-nil images, in order
            self.selectedImages.append(contentsOf: imagesToAdd.compactMap { $0 })
        }
    }

    // Story block functions
    func editStoryBlock(_ block: PortalWriteBlock) {
        if let idx = storyBlocks.firstIndex(where: { $0.id == block.id }) {
            storyBlocks[idx] = block
        }
    }

    func deleteStoryBlock(_ block: PortalWriteBlock) {
        storyBlocks.removeAll { $0.id == block.id }
    }

    func moveStoryBlockUp(at index: Int) {
        guard index > 0 else { return }
        storyBlocks.swapAt(index, index - 1)
        for i in storyBlocks.indices {
            storyBlocks[i].order = i
        }
    }

    func moveStoryBlockDown(at index: Int) {
        guard index < storyBlocks.count - 1 else { return }
        storyBlocks.swapAt(index, index + 1)
        for i in storyBlocks.indices {
            storyBlocks[i].order = i
        }
    }

    func save(completion: @escaping () -> Void) {
        let boundary = UUID().uuidString
        let isNew = portalId == 0
        let endpoint = isNew ? "/api/portal/" : "/api/portal/edit"
        guard let url = URL(string: "\(APIConfig.baseURL)\(endpoint)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()
        func appendFormField(_ name: String, _ value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        if !isNew {
            appendFormField("portal_id", "\(portalId)")
        }
        appendFormField("users_id", "\(userId)")
        appendFormField("name", name)
        appendFormField("subtitle", subtitle)
        appendFormField("about", about)
        appendFormField("portal_type", portalType)
        if portalType == "event" {
            let dtFormatter = DateFormatter()
            dtFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
            dtFormatter.locale = Locale(identifier: "en_US_POSIX")
            appendFormField("event_datetime", dtFormatter.string(from: eventDatetime))
            appendFormField("event_location", eventLocation)
            appendFormField("event_timezone", eventTimezone.isEmpty ? "UTC" : eventTimezone)
            appendFormField("event_duration_minutes", "\(eventDurationMinutes)")
        }

        // Save story blocks as aTexts (with position for ordering)
        let texts: [[String: String]] = storyBlocks.enumerated().map { idx, block in
            [
                "title": block.title ?? "",
                "text": block.content,
                "section": "story",
                "position": "\(idx)"
            ]
        }
        if let textsData = try? JSONSerialization.data(withJSONObject: texts) {
            appendFormField("aTexts", String(data: textsData, encoding: .utf8) ?? "")
        }

        // --- DEBUG: Print selectedLeads and aLeadsIDs JSON before sending ---
        print("Selected Leads:", selectedLeads.map { $0.id })
        if !selectedLeads.isEmpty {
            let leadIdsArray = selectedLeads.map { $0.id }
            if let data = try? JSONSerialization.data(withJSONObject: leadIdsArray) {
                let jsonString = String(data: data, encoding: .utf8) ?? ""
                print("aLeadsIDs JSON:", jsonString)
                appendFormField("aLeadsIDs", jsonString)
            }
        }

        for (idx, image) in selectedImages.prefix(maxImages).enumerated() {
            if let imageData = image.jpegData(compressionQuality: 0.85) {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"images\"; filename=\"portal_image_\(idx).jpg\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
                body.append(imageData)
                body.append("\r\n".data(using: .utf8)!)
            }
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                completion()
            }
        }.resume()
    }
}

// MARK: - Optional String Binding Helper

extension Binding where Value == String? {
    init(_ source: Binding<String?>, default defaultValue: String) {
        self.init(
            get: { source.wrappedValue ?? defaultValue },
            set: { source.wrappedValue = $0 }
        )
    }

    var unwrapped: Binding<String> {
        Binding<String>(
            get: { self.wrappedValue ?? "" },
            set: { self.wrappedValue = $0 }
        )
    }
}

// MARK: - EditableGoalView Subview

struct EditableGoalView: View {
    @Binding var goal: EditableGoal

    var body: some View {
        VStack(alignment: .leading) {
            TextField("Goal Title", text: $goal.title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Goal Subtitle", text: Binding($goal.subtitle, default: "").unwrapped)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.vertical, 4)
    }
}

// MARK: - PortalStoryBlocksEditorView

struct PortalStoryBlocksEditorView: View {
    @ObservedObject var viewModel: EditPortalViewModel

    @State private var showDeleteAlert = false
    @State private var blockToDelete: PortalWriteBlock?
    @State private var showAddStorySheet = false
    @State private var editingBlock: PortalWriteBlock? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with title and add button
            HStack {
                Text("Story")
                    .font(.title2)
                    .fontWeight(.medium)
                Spacer()
                Button(action: {
                    showAddStorySheet = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                }
            }
            .padding(.top, 8)

            if viewModel.storyBlocks.isEmpty {
                Text("No content yet. Tap + to add a story block.")
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                ForEach(Array(viewModel.storyBlocks.enumerated()), id: \.element.id) { index, block in
                    VStack(alignment: .leading, spacing: 4) {
                        if let title = block.title, !title.isEmpty {
                            Text(title)
                                .font(.title2)
                                .fontWeight(.medium)
                        }

                        // Display content as plain text
                        Text(block.content)
                            .font(.title3)
                        HStack(spacing: 16) {
                            // Reorder buttons
                            HStack(spacing: 4) {
                                if index > 0 {
                                    Button(action: { viewModel.moveStoryBlockUp(at: index) }) {
                                        Image(systemName: "chevron.up")
                                            .foregroundColor(.gray)
                                    }
                                }
                                if index < viewModel.storyBlocks.count - 1 {
                                    Button(action: { viewModel.moveStoryBlockDown(at: index) }) {
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            Spacer()
                            Button("Edit") {
                                editingBlock = block
                            }
                            .font(.title3)
                            .foregroundColor(.blue)
                            Button("Delete") {
                                blockToDelete = block
                                showDeleteAlert = true
                            }
                            .font(.title3)
                            .foregroundColor(.red)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                }
            }
        }
        .padding(.vertical)
        .sheet(item: $editingBlock) { block in
            EditStoryBlockView(
                block: block,
                onSave: { title, content in
                    // Update existing block
                    var updated = block
                    updated.title = title
                    updated.content = content
                    viewModel.editStoryBlock(updated)
                    editingBlock = nil
                },
                onCancel: {
                    editingBlock = nil
                }
            )
        }
        .sheet(isPresented: $showAddStorySheet) {
            EditStoryBlockView(
                block: nil,
                onSave: { title, content in
                    // Add new block
                    let newBlock = PortalWriteBlock(title: title, content: content, order: (viewModel.storyBlocks.last?.order ?? 0) + 1)
                    viewModel.storyBlocks.append(newBlock)
                },
                onCancel: {}
            )
        }
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Delete Story Block"),
                message: Text("Are you sure you want to delete this story block? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    if let block = blockToDelete {
                        viewModel.deleteStoryBlock(block)
                        blockToDelete = nil
                    }
                },
                secondaryButton: .cancel {
                    blockToDelete = nil
                }
            )
        }
    }
}

// MARK: - AddLeadsSheet

struct AddLeadsSheet: View {
    @Binding var selectedLeads: [User]
    let userId: Int

    @State private var networkMembers: [User] = []
    @State private var loading = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List(networkMembers, id: \.id) { user in
                UserSelectionRow(
                    title: user.displayName,
                    isSelected: selectedLeads.contains(where: { $0.id == user.id })
                ) {
                    if let idx = selectedLeads.firstIndex(where: { $0.id == user.id }) {
                        selectedLeads.remove(at: idx)
                    } else {
                        selectedLeads.append(user)
                    }
                }
            }
            .navigationTitle("Select Leads")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                fetchNetworkMembers()
            }
        }
    }

    func fetchNetworkMembers() {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/user/members_of_my_network") else {
            self.loading = false
            return
        }
        var request = URLRequest(url: url)
        if let token = UserDefaults.standard.string(forKey: "jwtToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        URLSession.shared.dataTask(with: request) { data, _, _ in
            defer { loading = false }
            guard let data = data else { return }
            if let decoded = try? JSONDecoder().decode([String: [User]].self, from: data),
               let users = decoded["result"] {
                DispatchQueue.main.async {
                    self.networkMembers = users
                }
            }
        }.resume()
    }
}

// MARK: - UserSelectionRow (unique for this file)

struct UserSelectionRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
}

// MARK: - Refactored Subviews for EditPortalView

struct PortalImagesSection: View {
    @ObservedObject var viewModel: EditPortalViewModel
    @Binding var photoPickerItems: [PhotosPickerItem]

    var body: some View {
        PhotosPicker(
            selection: $photoPickerItems,
            maxSelectionCount: 10 - viewModel.selectedImages.count,
            matching: .images,
            photoLibrary: .shared()
        ) {
            Text(viewModel.selectedImages.isEmpty ? "Add Images" : "Add More Images")
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.vertical, 8)
        }
        .onChange(of: photoPickerItems) { newItems in
            viewModel.loadImages(from: newItems)
        }

        if !viewModel.selectedImages.isEmpty {
            TabView(selection: $viewModel.mainImageIndex) {
                ForEach(Array(viewModel.selectedImages.enumerated()), id: \.offset) { idx, image in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .clipped()
                            .cornerRadius(8)
                            .tag(idx)
                        if idx == 0 {
                            Text("Main Icon")
                                .font(.caption2)
                                .padding(5)
                                .background(Color.black.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(6)
                                .padding([.top, .leading], 8)
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                        }
                        if idx != 0 {
                            Button(action: {
                                viewModel.removeImage(at: idx)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .padding(8)
                            }
                        }
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .frame(height: 190)
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 180)
                .cornerRadius(8)
                .overlay(Text("No Images Selected").foregroundColor(.secondary))
        }

        Text("First image is used as Portal Icon")
            .font(.caption)
            .foregroundColor(.secondary)
    }
}

struct PortalInfoSection: View {
    @ObservedObject var viewModel: EditPortalViewModel

    var body: some View {
        Group {
            TextField("Portal Name", text: $viewModel.name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Subtitle", text: $viewModel.subtitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("About", text: $viewModel.about)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

struct PortalLeadsSection: View {
    @ObservedObject var viewModel: EditPortalViewModel
    @Binding var showAddLeadsSheet: Bool
    let userId: Int

    var body: some View {
        Button(action: { showAddLeadsSheet = true }) {
            HStack {
                Text("Add Leads")
                Spacer()
                if !viewModel.selectedLeads.isEmpty {
                    Text("\(viewModel.selectedLeads.count) selected")
                        .foregroundColor(.secondary)
                }
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)
        }
        .sheet(isPresented: $showAddLeadsSheet) {
            AddLeadsSheet(
                selectedLeads: $viewModel.selectedLeads,
                userId: userId
            )
        }
    }
}

struct PaymentSettingsSection: View {
    let portalDetail: PortalDetail?
    let userId: Int
    let portalId: Int
    let portalName: String

    var body: some View {
        if portalDetail?.users_id == userId {
            Divider()
                .padding(.vertical, 8)
            NavigationLink(destination: PortalPaymentSetup(portalId: portalId, portalName: portalName)) {
                HStack {
                    Image(systemName: "creditcard.fill")
                        .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                    Text("Payment Settings")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - PortalTypeSection

struct PortalTypeSection: View {
    @ObservedObject var viewModel: EditPortalViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Portal Type Picker
            HStack {
                Text("Type")
                    .foregroundColor(.primary)
                Spacer()
                Menu {
                    ForEach(portalTypeOptions, id: \.value) { option in
                        Button(option.label) {
                            viewModel.portalType = option.value
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(portalTypeOptions.first(where: { $0.value == viewModel.portalType })?.label ?? "General")
                            .foregroundColor(.primary)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
                }
            }

            // Event-only fields
            if viewModel.portalType == "event" {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Event Details")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    DatePicker(
                        "Date & Time",
                        selection: $viewModel.eventDatetime,
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    TextField("Location", text: $viewModel.eventLocation)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    HStack {
                        Text("Timezone")
                            .foregroundColor(.primary)
                        Spacer()
                        Menu {
                            ForEach(eventTimezoneOptions, id: \.self) { tz in
                                Button(tz) {
                                    viewModel.eventTimezone = tz
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(viewModel.eventTimezone.isEmpty ? "Select Timezone" : viewModel.eventTimezone)
                                    .foregroundColor(viewModel.eventTimezone.isEmpty ? .secondary : .primary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                        }
                    }

                    Stepper(
                        "Duration: \(viewModel.eventDurationMinutes) min",
                        value: $viewModel.eventDurationMinutes,
                        in: 15...480,
                        step: 15
                    )
                }
                .padding()
                .background(Color(UIColor.systemGray6).opacity(0.5))
                .cornerRadius(10)
            }
        }
    }
}

// MARK: - EditPortalView

struct EditPortalView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EditPortalViewModel
    @State private var photoPickerItems: [PhotosPickerItem] = []
    @State private var showAddLeadsSheet = false
    @State private var showDeleteAlert = false // <-- Added for portal delete

    let userId: Int

    init(portal: PortalDetail, userId: Int) {
        _viewModel = StateObject(wrappedValue: EditPortalViewModel(portal: portal, userId: userId))
        self.userId = userId
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                        .font(.system(size: 20))
                }
                Spacer()
                Text("Edit Portal")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
                Button("Save") {
                    viewModel.save {
                        dismiss()
                    }
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.green)
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

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    PortalImagesSection(viewModel: viewModel, photoPickerItems: $photoPickerItems)
                    PortalInfoSection(viewModel: viewModel)
                    PortalTypeSection(viewModel: viewModel)
                    PortalLeadsSection(viewModel: viewModel, showAddLeadsSheet: $showAddLeadsSheet, userId: userId)
                    PaymentSettingsSection(
                        portalDetail: viewModel.portalDetail,
                        userId: userId,
                        portalId: viewModel.portalId,
                        portalName: viewModel.name
                    )
                    PortalStoryBlocksEditorView(viewModel: viewModel)
                    // --- Delete Portal Button ---
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Text("Delete Portal")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .padding(.top, 24)
                }
                .padding()
            }
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
        .navigationBarHidden(true)
        // --- Delete Portal Confirmation Alert ---
        .alert("Delete Portal?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                deletePortal()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this portal? This cannot be undone.")
        }
    }

    // --- Delete Portal Function ---
    private func deletePortal() {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/portal/delete"),
              !viewModel.jwtToken.isEmpty else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(viewModel.jwtToken)", forHTTPHeaderField: "Authorization")
        let params: [String: Any] = [
            "portal_id": viewModel.portalId,
            "user_id": viewModel.userId
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: params)
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    dismiss()
                } else {
                    // Optionally show error
                }
            }
        }.resume()
    }
}
