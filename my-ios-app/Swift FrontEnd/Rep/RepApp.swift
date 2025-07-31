//  RepApp.swift
//  Rep
//
//  Created by Adam Novak on 06.19.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

import SwiftUI

@main
struct RepApp: App {
    @State private var rootReloadKey = UUID()

    var body: some Scene {
        WindowGroup {
            RootAppView()
                .id(rootReloadKey)
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ForceRootReload"))) { _ in
                    rootReloadKey = UUID()
                }
        }
    }
}

// MARK: - RootAppView

struct RootAppView: View {
    @AppStorage("userId") var userId: Int = 0
    @AppStorage("jwtToken") var jwtToken: String = ""
    @AppStorage("isRegistered") var isRegistered: Bool = false
    @AppStorage("onboardingComplete") var onboardingComplete: Bool = false
    @AppStorage("onboardingUserName") var onboardingUserName: String = ""
    @AppStorage("onboardingProfileImageData") var onboardingProfileImageData: Data?

    var onboardingProfileImage: UIImage? {
        if let data = onboardingProfileImageData {
            return UIImage(data: data)
        }
        return nil
    }

    var sessionKey: String {
        "\(userId)-\(jwtToken)-\(isRegistered)-\(onboardingComplete)"
    }

    var body: some View {
        NavigationStack {
            if !isRegistered {
                RegisterNewProfileView()
            } else if !onboardingComplete {
                OnboardingFlowEntryView()
            } else if !jwtToken.isEmpty && userId > 0 {
                MainScreen()
            } else {
                LoginView()
            }
        }
        .id(sessionKey)
    }
}

// MARK: - OnboardingFlowEntryView

struct OnboardingFlowEntryView: View {
    @AppStorage("onboardingUserName") var onboardingUserName: String = ""
    @AppStorage("onboardingProfileImageData") var onboardingProfileImageData: Data?
    @AppStorage("acceptedTermsOfUse") var acceptedTermsOfUse: Bool = false

    enum OnboardingStep {
        case profile
        case terms
        case onboarding
    }
    @State private var step: OnboardingStep = .profile

    @State private var profileInfo = ProfileInfo(
        firstName: "",
        lastName: "",
        skills: [],
        type: .lead,
        cityName: "",
        image: nil,
        about: "",
        broadcast: "",
        otherSkill: ""
    )
    @StateObject private var onboardingProfileVM = ProfileInfoViewModel(
        profileInfo: ProfileInfo(
            firstName: "",
            lastName: "",
            skills: [],
            type: .lead,
            cityName: "",
            image: nil,
            about: "",
            broadcast: "",
            otherSkill: ""
        ),
        mode: .edit
    )

    var onboardingProfileImage: UIImage? {
        if let data = onboardingProfileImageData {
            return UIImage(data: data)
        }
        return nil
    }

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .profile:
                    EditProfileView(
                        viewModel: onboardingProfileVM,
                        showOnboardingAfterSave: true,
                        onSave: { _ in
                            onboardingUserName = (onboardingProfileVM.profileInfo.firstName + " " + onboardingProfileVM.profileInfo.lastName).trimmingCharacters(in: .whitespaces)
                            if let image = onboardingProfileVM.profileInfo.image, let data = image.jpegData(compressionQuality: 0.8) {
                                onboardingProfileImageData = data
                            }
                            if !acceptedTermsOfUse {
                                step = .terms
                            } else {
                                step = .onboarding
                            }
                        }
                    )
                case .terms:
                    TermsOfUseView {
                        acceptedTermsOfUse = true
                        step = .onboarding
                    }
                case .onboarding:
                    OnboardingView(
                        userName: onboardingUserName,
                        profileImage: onboardingProfileImage
                    )
                }
            }
        }
    }
}
