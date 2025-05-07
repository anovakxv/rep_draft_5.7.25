//
//  ProfileInfoView.swift
//  Rep 
//
//  Created by Dmytro Holovko on 10.12.2023.
//

import SwiftUI
import Combine

struct ProfileInfoModel {
    var firstName: String
    var lastName: String
    var skils: Set<RepSkillsModel>
    var type: RepTypeModel
    var image: ImageItem
    
    init(
        firstName: String,
        lastName: String,
        skils: Set<RepSkillsModel>,
        type: RepTypeModel,
        image: ImageItem
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.skils = skils
        self.type = type
        self.image = image
    }
}

extension ProfileInfoModel {
    var displayedName: String {
        if lastName.isEmpty {
            firstName
        } else {
            firstName + " " + lastName
        }
    }
    
    var displayedSkils: String {
        Array(skils.map { $0.rawValue }).joined(separator: " • ")
    }
}

class ProfileInfoViewModel: ObservableObject {
    @Published var profileInfo: ProfileInfoModel
    @Published var isEditing: Bool = false
    @Published var isAddingPhoto: Bool = false
    
    @Published var items = [ImageItem]()
    
    private var cancellables = Set<AnyCancellable>()
    private var originalProfileInfo: ProfileInfoModel
    
    init(profileInfo: ProfileInfoModel) {
        self.profileInfo = profileInfo
        self.originalProfileInfo = profileInfo
        
        $items.sink { [weak self] items in
            guard let self,
                  let lastItem = items.last
            else { return }
            self.profileInfo.image = lastItem
        }
        .store(in: &cancellables)
    }
    
    func done() {
        isEditing = false
    }
    
    func cancel() {
        profileInfo = originalProfileInfo
        isEditing = false
    }
    
    func logOut() {
        
    }
    
    func edit() {
        isEditing = true
    }
    
    func setNewPhoto() {
        isAddingPhoto = true
    }
}

struct ProfileInfoView: View {
    @ObservedObject var viewModel: ProfileInfoViewModel
    
    init(viewModel: ProfileInfoViewModel) {
        self.viewModel = viewModel
    }
    
    
    var body: some View {
        List {
            VStack(alignment: .center, spacing: 12.0) {
                GridItemView(
                    size: 120.0,
                    item: viewModel.profileInfo.image
                )
                .clipShape(.circle)
                
                if viewModel.isEditing {
                    Button("Set New Photo", action: viewModel.setNewPhoto)
                        .buttonStyle(.borderless)
                } else {
                    VStack(alignment: .center, spacing: 8.0) {
                        Text(viewModel.profileInfo.displayedName)
                            .font(.title)
                            .fontWeight(.semibold)
                        VStack(alignment: .center, spacing: 24.0) {
                            Text(viewModel.profileInfo.type.description)
                            Text(viewModel.profileInfo.displayedSkils)
                                .font(.footnote)
                        }
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                }
            }
            .listRowBackground(viewModel.isEditing ? Color.clear : Color(UIColor.secondarySystemBackground))
            .frame(maxWidth: .infinity)
            
            if viewModel.isEditing {
                
                Section {
                    TextField("First Name", text: $viewModel.profileInfo.firstName)
                    TextField("Last Name", text: $viewModel.profileInfo.lastName)
                } footer: {
                    Text("Enter your name and add an optional profile photo.")
                }
                
                Section {
                    MultiPicker(
                        RepTypeModel.title,
                        selection: $viewModel.profileInfo.type
                    ) {
                        ForEach(RepTypeModel.allCases) { role in
                            Text(role.rawValue)
                                .mpTag(role)
                        }
                    }
                    .mpPickerStyle(.navigationLink)
                    
                    MultiPicker(
                        RepSkillsModel.title,
                        selection: $viewModel.profileInfo.skils
                    ) {
                        ForEach(RepSkillsModel.allCases) { skill in
                            Text(skill.rawValue)
                                .mpTag(skill)
                                .disabled(true)
                        }
                    }
                    .mpPickerStyle(.navigationLink)
                    .choiceRepresentationStyle(.rich)
                    .maxValues(3)
                } footer: {
                    Text("Choose rep type and rep skills.")
                }
                
            } else {
                EmptyView()
            }
                Section {
                    Button("Log Out", role: .destructive, action: viewModel.logOut)
                    .frame(maxWidth: .infinity)
                }
        }
        .navigationTitle(viewModel.isEditing ? "Edit Profile" : "Profile Info")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if viewModel.isEditing {
                    Button("Cancel", action: viewModel.cancel)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if viewModel.isEditing {
                    Button("Done", action: viewModel.done)
                        .fontWeight(.semibold)
                } else {
                    Button("Edit", action: viewModel.edit)
                }
            }
        }
        .sheet(isPresented: $viewModel.isAddingPhoto) {
            PhotoPicker(items: $viewModel.items)
        }
    }
}

#Preview {
    NavigationStack {
        ProfileInfoView(
            viewModel: .init(
                profileInfo: .init(
                    firstName: "Alex",
                    lastName: "Cooper",
                    skils: [
                        .cantentGraphics,
                        .eventsPlanning,
                        .hrProductivity
                    ],
                    type: .lead,
                    image: eventsImageItem
                )
            )
        )
    }
}


let pp = ProfileInfoModel(
            firstName: "Alex",
            lastName: "Cooper",
            skils: [
                .cantentGraphics,
                .eventsPlanning,
                .hrProductivity
            ],
            type: .lead,
            image: eventsImageItem
)
