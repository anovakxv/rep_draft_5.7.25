//
//  PortalPage.swift
//  Rep 
//
//  Created by Dmytro Holovko on 28.10.2023.
//

import SwiftUI
import _PhotosUI_SwiftUI


@MainActor class PortalViewModel: ObservableObject {
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
                        
                        TextField("Description", text: $viewModel.portal.title)

                    }
                    VStack {
                        HStack {
                            Text("Description:")
                                .font(.caption)
                                .bold()
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        TextField("Description", text: $viewModel.portal.subtitle)

                    }
                    VStack {
                        HStack {
                            Text("City:")
                                .font(.caption)
                                .bold()
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        TextField("Description", text: $viewModel.portal.city)

                    }
                }
                
                Section("Aditional Info") {
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
                            
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            
                        }
                    }
                }
                .navigationTitle("Edit Portal Info")
        }.accentColor(.green)
    }
        
    
}

#Preview {
    EditPortalView(
        viewModel: .init(portal: portals.first!)
    )
}

struct PortalPage: View {

    @ObservedObject private var viewModel: PortalViewModel
    
    init(viewModel: PortalViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack {
            ImageTabView(imageItems: viewModel.portal.imageItems)
                .frame(height: 236)
            VStack {
                picker
                pickedViews
            }
        }
        .navigationTitle(viewModel.portal.title)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                ToolBar(action: { viewModel.isConfirmationDialogPresented = true})
            }
        }.onRotate { orientation in
            viewModel.isImageTabViewPresented = orientation == .landscapeLeft || orientation == .landscapeRight
            
        }
        .sheet(isPresented: $viewModel.isEditPresented) {
            EditPortalView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.isImageTabViewPresented) {
            ImageTabView(imageItems: viewModel.portal.imageItems)
        }
        .confirmationDialog(
            "Choose Action",
            isPresented: $viewModel.isConfirmationDialogPresented
        ) {
            Button(
                action: {
                    
                }, label: {
                    Text("Join Team")
                }
            )
//            .disabled(true)
            Button(
                action: {
                    
                }, label: {
                    Text("Share Portal")
                }
            )
//            .disabled(true)
            Button(
                action: {
                    
                }, label: {
                    Text("Support")
                }
            )
//            .disabled(true)
            Button(
                action: {
                    viewModel.isEditPresented = true
                }, label: {
                    Text("Edit Portal")
                }
            )
        }
    }
    
    @ViewBuilder
    var picker: some View {
        VStack {
            Picker("", selection: $viewModel.section) {
                Text(Texts.story).tag(0)
                Text(Texts.offering).tag(1)
                Text(Texts.results).tag(2)
            }
            .pickerStyle(.segmented)
            Divider()
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    var pickedViews: some View {
        ScrollView {
            VStack {
                switch viewModel.section {
                case 0: story
                case 1: offering
                case 2: results
                default: EmptyView()
                }
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    var story: some View {
        HStack {
            Text(Texts.leads)
                .font(.headline)
            ForEach(viewModel.portal.leads) { lead in
                VStack {
                    Image(lead.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: Constants.leadImageSize, height: Constants.leadImageSize)
                        .cornerRadius(Constants.leadImageSize / 2)
                    Text(lead.shortName)
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
            }
            Spacer()
        }
        Divider()
        VStack(alignment: .leading) {
            Text(Texts.description)
                .font(.headline)
            Text(viewModel.portal.description)
                .font(.body)
        }
        
    }
    
    @ViewBuilder
    var offering: some View {
        VStack(alignment: .leading) {
            Text(Texts.weOffer)
                .font(.headline)
            Text(viewModel.portal.description)
                .font(.body)
        }
    }
    
    @ViewBuilder
    var results: some View {
        ForEach(goals) { goal in
            VStack {
                GoalListItem(goal: goal)
                Divider()
            }
        }
    }
}

private extension PortalPage {
    enum Texts {
        static let results = "Results"
        static let offering = "Offering"
        static let weOffer = "We Offer"
        static let story = "Story"
        static let leads = "Leads"
        static let description = "Description"
    }
    
    enum Constants {
        static let leadImageSize: CGFloat = 28.0
        static let headerImageHeight: CGFloat = 250.0
    }
}

#Preview {
    NavigationStack {
        PortalPage(
            viewModel: .init(portal: portals.first!)
        )
    }
}

// Our custom view modifier to track rotation and
// call our action
struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(UIDevice.current.orientation)
            }
    }
}

// A View wrapper to make the modifier easier to use
extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}
