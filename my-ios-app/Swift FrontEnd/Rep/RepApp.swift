//  RepApp.swift
//  Rep
//
//  Created by Adam Novak on 06.19.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

import SwiftUI
import UserNotifications

@main
struct RepApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var rootReloadKey = UUID()

    init() {
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            RootAppView()
                .id(rootReloadKey)
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ForceRootReload"))) { _ in
                    rootReloadKey = UUID()
                }
                .preferredColorScheme(.light)
        }
    }
}

// MARK: - AppDelegate for Push Notifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")

        // Send token to backend
        let jwtToken = UserDefaults.standard.string(forKey: "jwtToken") ?? ""
        let userId = UserDefaults.standard.integer(forKey: "userId")
        guard !jwtToken.isEmpty, userId > 0 else {
            print("No jwtToken or userId, not sending device token to backend.")
            return
        }
        guard let url = URL(string: "\(APIConfig.baseURL)/api/user/device_token") else {
            print("Invalid backend URL for device token registration.")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        let body: [String: Any] = [
            "device_token": token
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Failed to send device token to backend: \(error)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("Device token sent to backend, status: \(httpResponse.statusCode)")
            }
        }.resume()
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
    }
}

// MARK: - Notification Delegate

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    // Handle foreground notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    // Handle tap on notification
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse,
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap logic here if needed
        completionHandler()
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