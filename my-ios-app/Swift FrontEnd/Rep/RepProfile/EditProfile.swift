//  EditProfile.swift
//  Rep
//
//  Created by Adam Novak on 06.23.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.

import SwiftUI
import Combine
import PhotosUI
import Foundation

// --- Custom Styled TextField for better placeholder and input readability ---
struct StyledProfileTextField: View {
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(Color(red: 0.35, green: 0.35, blue: 0.38))
                    .font(.custom("Inter", size: 16))
                    .padding(.leading, 16)
            }
            if isSecure {
                SecureField("", text: $text)
                    .foregroundColor(.black)
                    .font(.custom("Inter", size: 16))
                    .padding(.leading, 16)
            } else {
                TextField("", text: $text)
                    .foregroundColor(.black)
                    .font(.custom("Inter", size: 16))
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
                    .padding(.leading, 16)
            }
        }
        .padding(.vertical, 12)
        .background(Color(red: 0.98, green: 0.98, blue: 0.98))
        .cornerRadius(6)
    }
}

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
    var onSave: ((_ updatedUser: User?) -> Void)? = nil
    let showOnboardingAfterSave: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhoto: PhotosPickerItem? = nil

    @State private var showOnboarding = false

    // --- PATCH: Add onboarding-aware userId selection ---
    @AppStorage("pendingUserId") var pendingUserId: Int = 0
    @AppStorage("userId") var userId: Int = 0
    @AppStorage("onboardingComplete") var onboardingComplete: Bool = false
    @AppStorage("pendingFirstName") var pendingFirstName: String = ""
    @AppStorage("pendingLastName") var pendingLastName: String = ""

    // --- Delete Profile State ---
    @State private var showDeleteAlert = false

    init(viewModel: ProfileInfoViewModel, showOnboardingAfterSave: Bool = false, onSave: ((_ updatedUser: User?) -> Void)? = nil) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self.showOnboardingAfterSave = showOnboardingAfterSave
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 0) {
                        EditProfileHeaderView(
                            onCancel: { viewModel.cancel(); dismiss() },
                            onSave: {
                                viewModel.done { updatedUser in
                                    print("DEBUG: Save completion called")
                                    onSave?(updatedUser)
                                    if showOnboardingAfterSave {
                                        DispatchQueue.main.async {
                                            showOnboarding = true
                                        }
                                    } else {
                                        DispatchQueue.main.async {
                                            dismiss()
                                        }
                                    }
                                }
                            }
                        )

                        EditProfileInfoSection(viewModel: viewModel, selectedPhoto: $selectedPhoto)
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 12) {
                                StyledProfileTextField(
                                    placeholder: "First Name",
                                    text: $viewModel.profileInfo.firstName,
                                    autocapitalization: .words
                                )
                                StyledProfileTextField(
                                    placeholder: "Last Name",
                                    text: $viewModel.profileInfo.lastName,
                                    autocapitalization: .words
                                )
                            }
                            StyledProfileTextField(
                                placeholder: "Broadcast (optional)",
                                text: $viewModel.profileInfo.broadcast,
                                autocapitalization: .sentences
                            )
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Rep Type")
                                    .font(.custom("Inter", size: 16).weight(.bold))
                                    .foregroundColor(.black)
                                Picker("Rep Type", selection: $viewModel.profileInfo.type) {
                                    ForEach(RepTypeModel.allCases.filter { $0 != .admin }, id: \.self) { type in
                                        Text(type.description).tag(type)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity)
                                .background(Color(red: 0.98, green: 0.98, blue: 0.98))
                                .cornerRadius(6)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("City")
                                    .font(.custom("Inter", size: 16).weight(.bold))
                                    .foregroundColor(.black)
                                StyledProfileTextField(
                                    placeholder: "Enter City (optional)",
                                    text: $viewModel.profileInfo.cityName,
                                    autocapitalization: .words
                                )
                            }
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
                            StyledProfileTextField(
                                placeholder: "Other Skill (optional)",
                                text: $viewModel.profileInfo.otherSkill,
                                autocapitalization: .words
                            )
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                        Divider()
                        // --- Delete Profile Button ---
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Text("Delete Profile")
                                .font(.title2)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .padding(.top, 24)
                        // --- End Delete Profile Button ---
                        // Removed Spacer() here to keep content visible
                    }
                    .padding(.bottom, 400)
                }
                // Sticky debug button at the bottom
                VStack {
                    Spacer()
                    // Button("Go to Onboarding (Debug)") {
                    //     showOnboarding = true
                    // //}
                    //.padding(.bottom, 32)
                }
                // NavigationLink at the top level
                NavigationLink(
                    destination: OnboardingFlowEntryView()  // <-- No parameters needed
                        .navigationBarBackButtonHidden(true),
                    isActive: $showOnboarding
                ) {
                    EmptyView()
                }
            }
            .background(Color.white)
            .edgesIgnoringSafeArea(.bottom)
            .navigationBarHidden(true)
            .onAppear {
                // --- PATCH: Only prefill first/last name during onboarding, else fetch full profile ---
                if pendingUserId != 0 && !onboardingComplete {
                    viewModel.prefillFromRegistration(firstName: pendingFirstName, lastName: pendingLastName)
                } else {
                    viewModel.fetchProfile(for: userId)
                }
                viewModel.fetchAvailableSkills()
            }
            .onChange(of: selectedPhoto) { newItem in
                if let newItem {
                    Task {
                        do {
                            if let data = try await newItem.loadTransferable(type: Data.self),
                            let image = UIImage(data: data) {
                                viewModel.profileInfo.image = image
                            }
                        } catch {
                            print("DEBUG: Failed to load image from PhotosPicker:", error)
                        }
                    }
                }
            }
            // --- Delete Profile Alert ---
            .alert("Delete Profile?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    deleteProfile()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete your profile? This cannot be undone.")
            }
        }
    }

    // --- Delete Profile Function ---
    private func deleteProfile() {
        @AppStorage("acceptedTermsOfUse") var acceptedTermsOfUse: Bool = false // <-- Add this line

        guard let url = URL(string: "\(APIConfig.baseURL)/api/user/delete"),
            !viewModel.jwtToken.isEmpty else {
            viewModel.jwtToken = ""
            acceptedTermsOfUse = false // <-- Reset Terms flag on local delete
            dismiss()
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(viewModel.jwtToken)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    // Log out and clear session
                    viewModel.jwtToken = ""
                    acceptedTermsOfUse = false // <-- Reset Terms flag on delete
                    dismiss()
                } else {
                    // Optionally show error
                }
            }
        }.resume()
    }
}

// MARK: - MultipleSelectionRow for Skills
struct MultipleSelectionRow: View {
    let skill: SkillModel
    let isSelected: Bool
    let action: () -> Void

    // Smaller selector for a tighter row
    private let selectorSize: CGFloat = 18
    private let hitTarget: CGFloat = 28
    private let repGreen = Color(red: 0.549, green: 0.78, blue: 0.365)

    var body: some View {
        HStack(spacing: 12) {
            Text(skill.title)
                .font(.system(size: 18, weight: .bold)) // smaller font
                .foregroundColor(repGreen)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()

            Button(action: action) {
                ZStack {
                    Circle()
                        .stroke(repGreen, lineWidth: 2)
                        .frame(width: selectorSize, height: selectorSize)
                        .background(
                            Circle()
                                .fill(isSelected ? repGreen : Color.clear)
                        )
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: hitTarget, height: hitTarget)
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(isSelected ? "Deselect \(skill.title)" : "Select \(skill.title)"))
            .accessibilityAddTraits(.isButton)
        }
        .padding(.vertical, 4) // less vertical padding
        .contentShape(Rectangle())
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
        print("DEBUG: Fetching skills with JWT:", jwtToken)
        fetchSkills(jwtToken: jwtToken) { [weak self] skills in
            DispatchQueue.main.async {
                print("DEBUG: Skills loaded:", skills)
                self?.availableSkills = skills
                if self?.mode == .edit {
                    self?.patchSkillsForEdit()
                }
                print("DEBUG: profileInfo.skills after patch:", self?.profileInfo.skills ?? [])
            }
        }
    }

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

    // PATCH: Accept completion with updated user
    func done(completion: @escaping (_ updatedUser: User?) -> Void) {
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

        if !profileInfo.firstName.isEmpty { appendFormField("fname", profileInfo.firstName) }
        if !profileInfo.lastName.isEmpty { appendFormField("lname", profileInfo.lastName) }
        if !profileInfo.broadcast.isEmpty { appendFormField("broadcast", profileInfo.broadcast) }
        if !profileInfo.otherSkill.isEmpty { appendFormField("other_skill", profileInfo.otherSkill) }
        appendFormField("users_types_id", String(profileInfo.type.dbID))
        if !profileInfo.cityName.isEmpty { appendFormField("manual_city", profileInfo.cityName) }
        if !profileInfo.skills.isEmpty {
            let skillIds = profileInfo.skills.map { String($0.id) }.joined(separator: ",")
            appendFormField("aSkills", skillIds)
        }

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
            var updatedUser: User? = nil
            if let data = data {
                // PATCH: Parse updated user from backend response
                if let apiResponse = try? JSONDecoder().decode(UserProfileAPIResponse.self, from: data) {
                    updatedUser = apiResponse.result
                }
            }
            DispatchQueue.main.async {
                completion(updatedUser)
            }
        }.resume()
    }

    // --- PATCH: Only fetch full profile for normal flow, not onboarding ---
    func fetchProfile(for userId: Int) {
        guard userId != 0,
              let url = URL(string: "\(APIConfig.baseURL)/api/user/profile?users_id=\(userId)"),
              !jwtToken.isEmpty else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let apiResponse = try? JSONDecoder().decode(UserProfileAPIResponse.self, from: data) else { return }
            DispatchQueue.main.async {
                self.profileInfo.firstName = apiResponse.result.fname ?? ""
                self.profileInfo.lastName = apiResponse.result.lname ?? ""
                self.profileInfo.cityName = apiResponse.result.city ?? ""
                self.profileInfo.broadcast = apiResponse.result.broadcast ?? ""
                self.profileInfo.otherSkill = apiResponse.result.other_skill ?? ""
                self.profileInfo.type = RepTypeModel(rawValue: apiResponse.result.userType ?? "") ?? .lead
                self.profileInfo.skills = Set(apiResponse.result.skills ?? [])
            }
        }.resume()
    }

    // --- PATCH: Prefill only first/last name for onboarding ---
    func prefillFromRegistration(firstName: String, lastName: String) {
        self.profileInfo.firstName = firstName
        self.profileInfo.lastName = lastName
    }
}
