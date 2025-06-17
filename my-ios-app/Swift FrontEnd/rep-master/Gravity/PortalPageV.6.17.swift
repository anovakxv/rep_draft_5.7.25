//
//  PortalPage.swift
//  Rep 
//
//  Created by Dmytro Holovko on 10.28.2023.
//  Updated by Adam Novak on 06.15.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.


import SwiftUI
import _PhotosUI_SwiftUI

// MARK: - Portal ViewModel

@MainActor
class PortalViewModel: ObservableObject {
    @Published var portal: PortalModel
    @Published var section = 0
    @Published var isImageTabViewPresented = false
    @Published var isConfirmationDialogPresented = false
    @Published var isEditPresented = false

    let originalPortalCopy: PortalModel

    init(portal: PortalModel) {
        self.portal = portal
        self.originalPortalCopy = portal
    }
}

// MARK: - Portal Page

struct PortalPage: View {
    @ObservedObject private var viewModel: PortalViewModel

    init(viewModel: PortalViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 0) {
            // Graphics section: edge-to-edge, 16:9 aspect ratio, no padding
            GeometryReader { geometry in
                ImageTabView(imageItems: viewModel.portal.imageItems)
                    .frame(width: geometry.size.width, height: geometry.size.width * 9 / 16)
                    .clipped()
            }
            .frame(height: UIScreen.main.bounds.width * 9 / 16)

            // Segmented Picker: directly below graphics
            CustomSegmentedPicker(
                segments: ["Story", "Offering", "Results"],
                selectedIndex: $viewModel.section
            )
            .padding(.horizontal)

            // Main Content
            Group {
                if viewModel.section == 0 {
                    PortalStorySection(portal: viewModel.portal)
                } else if viewModel.section == 1 {
                    PortalOfferingSection(portal: viewModel.portal)
                } else if viewModel.section == 2 {
                    PortalResultsSection(goals: goals)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            Spacer()
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
        .navigationTitle(viewModel.portal.title)
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
            EditPortalView(viewModel: viewModel)
        }
    }
}

// MARK: - Graphics Section

struct ImageTabView: View {
    @Binding var imageItems: [PortalImageItem]

    var body: some View {
        TabView {
            ForEach(imageItems) { item in
                if let image = item.image {
                    Image(uiImage: image)
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
    let portal: PortalModel
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Leads")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(portal.leads) { lead in
                        VStack {
                            Image(lead.imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 28, height: 28)
                                .cornerRadius(14)
                            Text(lead.shortName)
                                .font(.caption2)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            Divider()
            Text("Description")
                .font(.headline)
            Text(portal.description)
                .font(.body)
        }
    }
}

struct PortalOfferingSection: View {
    let portal: PortalModel
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("We Offer")
                .font(.headline)
            Text(portal.description)
                .font(.body)
        }
    }
}

struct PortalResultsSection: View {
    let goals: [GoalModel]
    var body: some View {
        ForEach(goals) { goal in
            VStack {
                NavigationLink(destination: GoalDetailPage(goal: goal)) {
                    GoalListItem(goal: goal)
                }
                Divider()
            }
        }
    }
}

// MARK: - Edit Portal View

struct EditPortalView: View {
    @ObservedObject private var viewModel: PortalViewModel

    init(viewModel: PortalViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            List {
                Section("General Info") {
                    VStack {
                        HStack {
                            Text("Title:")
                                .font(.caption)
                                .bold()
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        TextField("Title", text: $viewModel.portal.title)
                    }
                    VStack {
                        HStack {
                            Text("Subtitle:")
                                .font(.caption)
                                .bold()
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        TextField("Subtitle", text: $viewModel.portal.subtitle)
                    }
                    VStack {
                        HStack {
                            Text("City:")
                                .font(.caption)
                                .bold()
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        TextField("City", text: $viewModel.portal.city)
                    }
                }
                Section("Additional Info") {
                    VStack {
                        HStack {
                            Text("About:")
                                .font(.caption)
                                .bold()
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        TextEditor(text: $viewModel.portal.description)
                            .frame(height: 100)
                            .padding(-5)
                    }
                    VStack {
                        HStack {
                            Text("Mission:")
                                .font(.caption)
                                .bold()
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        TextEditor(text: $viewModel.portal.description)
                            .frame(height: 100)
                            .padding(-5)
                    }
                }
                Section("Portal Assets") {
                    NavigationLink(
                        destination: { GridView(items: $viewModel.portal.imageItems) },
                        label: { Text("Edit Graphics") }
                    )
                    NavigationLink(
                        destination: { EmptyView() },
                        label: { Text("Portal Leads") }
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        // Cancel logic
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        // Save logic
                    }
                }
            }
            .navigationTitle("Edit Portal Info")
        }
        .accentColor(.green)
    }
}

// MARK: - Placeholder Models and Views

struct PortalModel: Identifiable {
    let id: Int
    var title: String
    var subtitle: String
    var city: String
    var description: String
    var imageItems: [PortalImageItem]
    var leads: [Lead]
}

struct PortalImageItem: Identifiable {
    let id: Int
    var image: UIImage?
}

struct Lead: Identifiable {
    let id: Int
    let imageName: String
    let shortName: String
}

struct Goal: Identifiable {
    let id: Int
    let title: String
}

struct GoalModel: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let progress: Int
    let chartData: [BarChartData]
}

struct BarChartData: Identifiable {
    let id = UUID()
    let value: Double
    let label: String
    let color: Color
}

struct GoalListItem: View {
    let goal: GoalModel

    var body: some View {
        HStack(spacing: 16) {
            BarChartView(data: goal.chartData)
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title)
                    .font(.headline)
                Text(goal.subtitle)
                    .font(.subheadline)
                Text("\(goal.progress)% [Recruiting]")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .frame(height: 64)
        .padding(.vertical, 4)
        .padding(.horizontal)
        .background(Color.white)
    }
}
struct GoalDetailPage: View {
    let goal: Goal
    var body: some View {
        Text("Goal: \(goal.title)")
    }
}

struct GridView: View {
    @Binding var items: [PortalImageItem]
    var body: some View {
        Text("Grid View Placeholder")
    }
}

// MARK: - Preview

let sampleLeads = [
    Lead(id: 1, imageName: "person.crop.circle", shortName: "JD"),
    Lead(id: 2, imageName: "person.crop.circle.fill", shortName: "AN")
]

let sampleImages = [
    PortalImageItem(id: 1, image: nil),
    PortalImageItem(id: 2, image: nil)
]

let samplePortal = PortalModel(
    id: 1,
    title: "Sample Portal",
    subtitle: "A great place to connect",
    city: "New York",
    description: "This is a sample portal description.",
    imageItems: sampleImages,
    leads: sampleLeads
)

let goals = [
    Goal(id: 1, title: "Grow
