//  Rep
//
//  Created by Adam Novak on 06.23.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.

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

// MARK: - EditPortalViewModel

class EditPortalViewModel: ObservableObject {
    @Published var name: String
    @Published var subtitle: String
    @Published var about: String
    @Published var section: Int = 0
    @Published var storyText: String
    @Published var offeringText: String
    @Published var goals: [EditableGoal]
    @Published var selectedImages: [UIImage] = []
    @Published var mainImageIndex: Int = 0

    let portalId: Int
    let userId: Int
    let maxImages = 10

    @AppStorage("jwtToken") var jwtToken: String = ""

    init(portal: PortalDetail, userId: Int) {
        self.portalId = portal.id
        self.userId = userId
        self.name = portal.name
        self.subtitle = portal.subtitle ?? ""
        self.about = portal.about ?? ""
        self.storyText = (portal.aTexts ?? []).first?.text ?? ""
        self.offeringText = portal.about ?? ""
        self.goals = (portal.aGoals ?? []).map { EditableGoal(goal: $0) }
        // Optionally load existing images from portal.aSections/aFiles if needed
    }

    func addGoal() {
        goals.append(EditableGoal(title: "", subtitle: "", progressPercent: nil, typeName: "", chartData: []))
    }

    func removeImage(at index: Int) {
        guard selectedImages.indices.contains(index) else { return }
        selectedImages.remove(at: index)
        // Defensive fix: always keep mainImageIndex in a valid range
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
        for item in itemsToLoad {
            item.loadTransferable(type: Data.self) { result in
                switch result {
                case .success(let data):
                    if let data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.selectedImages.append(image)
                        }
                    }
                case .failure(let error):
                    print("Failed to load image: \(error)")
                }
            }
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

        // Required fields
        if !isNew {
            appendFormField("portal_id", "\(portalId)")
        }
        appendFormField("user_id", "\(userId)")

        // Main fields
        appendFormField("name", name)
        appendFormField("subtitle", subtitle)
        appendFormField("about", about)
        // Add categories_id, cities_id, lead_id, visible, etc. as needed

        // Texts (story, offering, etc.)
        let texts: [[String: String]] = [
            ["title": "Story", "text": storyText, "section": "story"],
            ["title": "Offering", "text": offeringText, "section": "offering"]
        ]
        if let textsData = try? JSONSerialization.data(withJSONObject: texts) {
            appendFormField("aTexts", String(data: textsData, encoding: .utf8) ?? "")
        }

        // Images
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
                // Handle response, update UI, show error/success, etc.
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
            // Add more fields as needed
        }
        .padding(.vertical, 4)
    }
}

// MARK: - EditPortalView

struct EditPortalView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EditPortalViewModel
    @State private var photoPickerItems: [PhotosPickerItem] = []

    let userId: Int

    init(portal: PortalDetail, userId: Int) {
        _viewModel = StateObject(wrappedValue: EditPortalViewModel(portal: portal, userId: userId))
        self.userId = userId
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom Back Header
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
                    // Add/Change Images Button
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

                    // Editable Portal Images (swipeable)
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

                    // Editable Fields
                    Group {
                        TextField("Portal Name", text: $viewModel.name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        TextField("Subtitle", text: $viewModel.subtitle)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        TextField("About", text: $viewModel.about)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        // Add pickers for category, city, etc. as needed
                    }

                    // Editable Sections (Story, Offering, Results)
                    PortalSegmentedPicker(
                        segments: ["Story", "Offering", "Results"],
                        selectedIndex: $viewModel.section
                    )
                    .padding(.vertical, 8)

                    if viewModel.section == 0 {
                        // Editable Story Section
                        TextEditor(text: $viewModel.storyText)
                            .frame(height: 120)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                    } else if viewModel.section == 1 {
                        // Editable Offering Section
                        TextEditor(text: $viewModel.offeringText)
                            .frame(height: 120)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                    } else if viewModel.section == 2 {
                        // Editable Results Section (Goals)
                        ForEach($viewModel.goals) { $goal in
                            EditableGoalView(goal: $goal)
                        }
                        Button("+ Add Goal") {
                            viewModel.addGoal()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
                .padding()
            }
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
        .navigationBarHidden(true)
    }
}