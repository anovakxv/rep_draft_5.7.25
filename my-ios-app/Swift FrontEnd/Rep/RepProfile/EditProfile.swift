//  EditProfile.swift
//  Rep
//
//  Created by Adam Novak on 06.23.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.

import SwiftUI
import Combine
import PhotosUI
import Foundation

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
    var about: String // You may remove this property if not needed elsewhere
    var broadcast: String
    var otherSkill: String
}

// MARK: - EditProfileView

struct EditProfileView: View {
    @ObservedObject var viewModel: ProfileInfoViewModel
    var onSave: (() -> Void)? = nil
    let showOnboardingAfterSave: Bool // <-- Add this flag
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhoto: PhotosPickerItem? = nil

    // --- Onboarding Navigation State ---
    @State private var showOnboarding = false

    // Custom initializer to support @ObservedObject, onboarding flag, and onSave
    init(viewModel: ProfileInfoViewModel, showOnboardingAfterSave: Bool = false, onSave: (() -> Void)? = nil) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self.showOnboardingAfterSave = showOnboardingAfterSave
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                EditProfileHeaderView(
                    onCancel: { viewModel.cancel(); dismiss() },
                    onSave: {
                        viewModel.done {
                            onSave?()
                            if showOnboardingAfterSave {
                                showOnboarding = true
                            } else {
                                dismiss()
                            }
                        }
                    }
                )
                EditProfileInfoSection(viewModel: viewModel, selectedPhoto: $selectedPhoto)
                VStack(alignment: .leading, spacing: 16) {
                    // Name fields (first editable fields)
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
                    // Broadcast
                    TextField("Broadcast (optional)", text: $viewModel.profileInfo.broadcast)
                        .padding()
                        .background(Color(red: 0.98, green: 0.98, blue: 0.98))
                        .cornerRadius(6)
                    // Rep Type (own line)
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
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 0.98, green: 0.98, blue: 0.98))
                        .cornerRadius(6)
                    }
                    // City (own line)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("City")
                            .font(.custom("Inter", size: 16).weight(.bold))
                            .foregroundColor(.black)
                        TextField("Enter City (optional)", text: $viewModel.profileInfo.cityName)
                            .padding()
                            .background(Color(red: 0.98, green: 0.98, blue: 0.98))
                            .cornerRadius(6)
                    }
                    // Skills selector (dropdown, up to 3)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Select up to 3 Skills")
                            .font(.custom("Inter", size: 16).weight(.bold))
                            .foregroundColor(.black)
                        if viewModel.availableSkills.isEmpty {
                            ProgressView("Loading skills...")
                        } else {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 0) {
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
                                        Divider()
                                    }
                                }
                            }
                            .frame(height: min(200, CGFloat(viewModel.availableSkills.count) * 44))
                            Text("\(viewModel.profileInfo.skills.count) of 3 selected")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    // Other Skill
                    TextField("Other Skill (optional)", text: $viewModel.profileInfo.otherSkill)
                        .padding()
                        .background(Color(red: 0.98, green: 0.98, blue: 0.98))
                        .cornerRadius(6)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                Divider()
                Spacer()
                // --- NavigationLink to OnboardingView ---
                NavigationLink(
                    destination: OnboardingView(
                        userName: (viewModel.profileInfo.firstName + " " + viewModel.profileInfo.lastName).trimmingCharacters(in: .whitespaces),
                        profileImage: viewModel.profileInfo.image
                    )
                    .navigationBarBackButtonHidden(true),
                    isActive: $showOnboarding
                ) {
                    EmptyView()
                }
            }
            .background(Color.white)
            .navigationBarHidden(true)
            .onAppear {
                viewModel.fetchAvailableSkills()
            }
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
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(red: 0.549, green: 0.78, blue: 0.365)) // repGreen
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
        VStack(spacing: 0) {
            // This color bar fills the status bar area, matching system look
            Color.white
                .frame(height: UIApplication.shared.connectedScenes
                    .compactMap { ($0 as? UIWindowScene)?.keyWindow?.safeAreaInsets.top }
                    .first ?? 0)
                .ignoresSafeArea()
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
        .background(Color.white)
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
                print("DEBUG: availableSkills after set:", self?.availableSkills ?? [])
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
        // "about" field removed from request
        if !profileInfo.broadcast.isEmpty { appendFormField("broadcast", profileInfo.broadcast) }
        if !profileInfo.otherSkill.isEmpty { appendFormField("other_skill", profileInfo.otherSkill) }
        appendFormField("users_types_id", String(profileInfo.type.dbID))
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
