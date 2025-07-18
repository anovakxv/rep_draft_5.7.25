//  RepApp.swift
//  Rep
//
//  Created by Adam Novak on 06.19.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

import SwiftUI

@main
struct RepApp: App {
    @AppStorage("userId") var userId: Int = 0
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

    var body: some Scene {
        WindowGroup {
            if !isRegistered {
                RegisterNewProfileView(
                    // Optionally, you can pass closures to set onboardingUserName/onboardingProfileImageData
                )
            } else if !onboardingComplete {
                // Show onboarding flow (EditProfileView > OnboardingView)
                OnboardingFlowEntryView()
            } else if userId > 0 {
                MainScreen()
            } else {
                LoginView()
            }
        }
    }
}

// MARK: - OnboardingFlowEntryView

struct OnboardingFlowEntryView: View {
    @AppStorage("onboardingUserName") var onboardingUserName: String = ""
    @AppStorage("onboardingProfileImageData") var onboardingProfileImageData: Data?
    @State private var showOnboarding = false
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
            EditProfileView(
                viewModel: onboardingProfileVM,
                showOnboardingAfterSave: true,
                onSave: { _ in
                    onboardingUserName = (onboardingProfileVM.profileInfo.firstName + " " + onboardingProfileVM.profileInfo.lastName).trimmingCharacters(in: .whitespaces)
                    if let image = onboardingProfileVM.profileInfo.image, let data = image.jpegData(compressionQuality: 0.8) {
                        onboardingProfileImageData = data
                    }
                    showOnboarding = true
                }
            )
            .navigationDestination(isPresented: $showOnboarding) {
                OnboardingView(
                    userName: onboardingUserName,
                    profileImage: onboardingProfileImage
                )
            }
        }
    }
}

