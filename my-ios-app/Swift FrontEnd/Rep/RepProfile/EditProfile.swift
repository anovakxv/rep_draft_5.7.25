//  EditProfile.swift
//  Rep
//
//  Created by Adam Novak on 06.23.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.

import SwiftUI
import Combine
import PhotosUI

// MARK: - SkillModel

struct SkillModel: Identifiable, Hashable, Codable {
    let id: Int
    let title: String

    static func == (lhs: SkillModel, rhs: SkillModel) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - ProfileInfo Model

struct ProfileInfo {
    var firstName: String
    var lastName: String
    var skills: Set<SkillModel>
    var type: RepTypeModel
    var cityName: String
    var image: UIImage?
    var about: String
    var broadcast: String
    var otherSkill: String
}

// MARK: - EditProfileView

struct EditProfileView: View {
    @ObservedObject var viewModel: ProfileInfoViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToMainScreen = false
    @State private var selectedPhoto: PhotosPickerItem? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                EditProfileHeaderView(
                    onCancel: { viewModel.cancel(); dismiss() },
                    onSave: {
                        viewModel.done {
                            navigateToMainScreen = true
                        }
                    }
                )
                EditProfileInfoSection(viewModel: viewModel, selectedPhoto: $selectedPhoto)
                VStack(alignment: .leading, spacing: 12) {
                    TextField("About (optional)", text: $viewModel.profileInfo.about)
                        .padding()
                        .background(Color(red: 0.98, green: 0.98, blue: 0.98))
                        .cornerRadius(6)
                    TextField("Broadcast (optional)", text: $viewModel.profileInfo.broadcast)
                        .padding()
                        .background(Color(red: 0.98, green: 0.98, blue: 0.98))
                        .cornerRadius(6)
                    TextField("Other Skill (optional)", text: $viewModel.profileInfo.otherSkill)
                        .padding()
                        .background(Color(red: 0.98, green: 0.98, blue: 0.98))
                        .cornerRadius(6)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                Divider()
                ScrollView {
                    VStack(spacing: 24) {
                        // Rep Type & City
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Rep Type")
                                    .font(.custom("Inter", size: 16).weight(.bold))
                                    .foregroundColor(.black)
                                Picker("Rep Type", selection: $viewModel.profileInfo.type) {
                                    ForEach(RepTypeModel.allCases, id: \.self) { role in
                                        Text(role.rawValue).tag(role)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("City")
                                    .font(.custom("Inter", size: 16).weight(.bold))
                                    .foregroundColor(.black)
                                TextField("Enter City (optional)", text: $viewModel.profileInfo.cityName)
                                    .padding()
                                    .background(Color(red: 0.98, green: 0.98, blue: 0.98))
                                    .cornerRadius(6)
                            }
                        }
                        .padding(.horizontal, 24)
                        // Edit Skills (Dynamic) - SIMPLE MULTISELECT
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Edit Skills")
                                .font(.custom("Inter", size: 16).weight(.bold))
                                .foregroundColor(.black)
                            if viewModel.availableSkills.isEmpty {
                                ProgressView("Loading skills...")
                            } else {
                                List {
                                    ForEach(viewModel.availableSkills, id: \.self) { skill in
                                        MultipleSelectionRow(
                                            skill: skill,
                                            isSelected: viewModel.profileInfo.skills.contains(skill)
                                        ) {
                                            if viewModel.profileInfo.skills.contains(skill) {
                                                viewModel.profileInfo.skills.remove(skill)
                                            } else if viewModel.profileInfo.skills.count < 3 {
                                                viewModel.profileInfo.skills.insert(skill)
                                            }
                                        }
                                    }
                                }
                                .frame(height: min(200, CGFloat(viewModel.availableSkills.count) * 44))
                                .listStyle(.plain)
                                Text("\(viewModel.profileInfo.skills.count) of 3 selected")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal, 24)
                        // Name Fields
                        HStack(spacing: 12) {
                            TextField("First Name", text: $viewModel.profileInfo.firstName)
                                .padding()
                                .background(Color(red: 0.98, green: 0.98, blue: 0.98))
                                .cornerRadius(6)
                            TextField("Last Name", text: $viewModel.profileInfo.lastName)
                                .padding()
                                .background(Color(red: 0.98, green: 0.98, blue: 0.98))
                                .cornerRadius(6)
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 16)
                    Spacer()
                    VStack(spacing: 8) {
                        Text("+ Insert new writing section\n\nInsert body text, or copy paste in.")
                            .font(.custom("Inter", size: 16).weight(.bold))
                            .foregroundColor(Color(red: 0.48, green: 0.75, blue: 0.29))
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 16)
                        Button(action: {
                            // Add writing section action
                        }) {
                            Text("+")
                                .font(.custom("Inter", size: 16).weight(.bold))
                                .foregroundColor(.black)
                                .frame(width: 291, height: 41)
                                .background(Color(red: 0.48, green: 0.75, blue: 0.29))
                                .cornerRadius(6)
                                .shadow(color: Color(red: 0.48, green: 0.75, blue: 0.29, opacity: 0.10), radius: 3, x: 1, y: 4)
                        }
                    }
                    .padding(.bottom, 32)
                }
                .background(Color.white)
                .onChange(of: selectedPhoto) { newItem in
                    if let newItem {
                        Task {
                            if let data = try? await newItem.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                viewModel.profileInfo.image = image
                            }
                        }
                    }
                }
                NavigationLink(
                    destination: MainScreen(),
                    isActive: $navigateToMainScreen
                ) {
                    EmptyView()
                }
            }
            .background(Color.white.edgesIgnoringSafeArea(.all))
            .navigationBarHidden(true)
            .onAppear {
                viewModel.fetchAvailableSkills()
            }
        }
    }
}

// MARK: - MultipleSelectionRow for Skills
struct MultipleSelectionRow: View {
    let skill: SkillModel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(skill.title)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
}

// MARK: - Top Navigation Header (matches ProfileView)
struct EditProfileHeaderView: View {
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        HStack {
            Button(action: onCancel) {
                Image(systemName: "chevron.left")
                    .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                    .font(.system(size: 20))
            }
            Spacer()
            Text("Edit Profile")
                .font(.system(size: 20, weight: .bold))
            Spacer()
            Button(action: onSave) {
                Text("Save")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(red: 0.75, green: 0.74, blue: 0.29))
            }
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
    }
}

// MARK: - Profile Info Section (matches ProfileView)
struct EditProfileInfoSection: View {
    @ObservedObject var viewModel: ProfileInfoViewModel
    @Binding var selectedPhoto: PhotosPickerItem?

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            ZStack(alignment: .bottomTrailing) {
                if let image = viewModel.profileInfo.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 108, height: 108)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 108, height: 108)
                        .overlay(
                            Image(systemName: "person.crop.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.gray)
                        )
                }
                PhotosPicker(
                    selection: $selectedPhoto,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Text("+Edit\nPhoto")
                        .font(.custom("Inter", size: 16))
                        .foregroundColor(Color(red: 0.47, green: 0.47, blue: 0.47))
                        .multilineTextAlignment(.center)
                        .padding(6)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(8)
                }
                .offset(x: -10, y: 10)
            }
            VStack(alignment: .leading, spacing: 7) {
                Text(viewModel.profileInfo.type.description)
                    .font(.system(size: 17, weight: .bold))
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(viewModel.profileInfo.skills), id: \.self) { skill in
                        Text(skill.title)
                            .font(.system(size: 17))
                    }
                }
            }
            .padding(.top, 5)
            Spacer()
        }
        .padding(15)
    }
}

// MARK: - EditMode

enum EditMode {
    case edit
    case create
}

// MARK: - Preview Image

let eventsImageItem = UIImage(systemName: "person.crop.circle")

// MARK: - ViewModel

class ProfileInfoViewModel: ObservableObject {
    @Published var profileInfo: ProfileInfo
    @Published var isAddingPhoto: Bool = false
    @Published var items: [UIImage] = []
    @Published var availableSkills: [SkillModel] = []
    var mode: EditMode

    @AppStorage("jwtToken") var jwtToken: String = ""

    init(profileInfo: ProfileInfo, mode: EditMode) {
        self.profileInfo = profileInfo
        self.mode = mode
    }

    func fetchAvailableSkills() {
        fetchSkills(jwtToken: jwtToken) { [weak self] skills in
            DispatchQueue.main.async {
                self?.availableSkills = skills
                // Patch: If editing, update selected skills and otherSkill if needed
                if self?.mode == .edit {
                    self?.patchSkillsForEdit()
                }
            }
        }
    }

    // Patch: Pre-fill selected skills and otherSkill for Edit mode
    private func patchSkillsForEdit() {
        let userSkills = self.profileInfo.skills.map { $0.title }
        let matchedSkills = userSkills.compactMap { skillName in
            self.availableSkills.first(where: { $0.title == skillName })
        }
        let otherSkill = userSkills.first(where: { skillName in
            !self.availableSkills.contains(where: { $0.title == skillName })
        }) ?? ""
        self.profileInfo.skills = Set(matchedSkills)
        self.profileInfo.otherSkill = otherSkill
    }

    func cancel() {
        // Handle cancel logic if needed
    }

    func setNewPhoto() {
        isAddingPhoto = true
    }

    func done(completion: @escaping () -> Void) {
        // Prepare multipart/form-data body
        let boundary = UUID().uuidString
        guard let url = URL(string: "\(APIConfig.baseURL)/api/user/edit") else { return }
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

        // Add all fields (only add if not empty)
        if !profileInfo.firstName.isEmpty { appendFormField("fname", profileInfo.firstName) }
        if !profileInfo.lastName.isEmpty { appendFormField("lname", profileInfo.lastName) }
        if !profileInfo.about.isEmpty { appendFormField("about", profileInfo.about) }
        if !profileInfo.broadcast.isEmpty { appendFormField("broadcast", profileInfo.broadcast) }
        if !profileInfo.otherSkill.isEmpty { appendFormField("other_skill", profileInfo.otherSkill) }
        appendFormField("users_types_id", profileInfo.type.rawValue)
        if !profileInfo.cityName.isEmpty { appendFormField("manual_city", profileInfo.cityName) }
        if !profileInfo.skills.isEmpty {
            let skillIds = profileInfo.skills.map { String($0.id) }.joined(separator: ",")
            appendFormField("aSkills", skillIds)
        }

        // Add profile picture if changed
        if let image = profileInfo.image, let imageData = image.jpegData(compressionQuality: 0.8) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"profile_picture\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
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