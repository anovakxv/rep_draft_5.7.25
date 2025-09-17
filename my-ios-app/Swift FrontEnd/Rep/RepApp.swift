//  RepApp.swift
//  Rep
//
//  Created by Adam Novak on 06.19.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

import SwiftUI
import UserNotifications
import FirebaseCore
import FirebaseMessaging
import StripeCore
import Stripe

@main
struct RepApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var rootReloadKey = UUID()

    init() {
        FirebaseApp.configure()
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

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate {
    private var hasAPNSToken = false
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared

        // Add this observer for chat cleanup
        NotificationCenter.default.addObserver(
            forName: .cleanupGroupChat,
            object: nil,
            queue: .main
        ) { notification in
            // Force resource cleanup
            if let chatId = notification.userInfo?["chatId"] as? Int {
                // Make sure we've left the room
                RealtimeSocketManager.shared.leave(chatId: chatId)
            }
        }

      // Stripe initialization
        StripeAPI.defaultPublishableKey = "pk_live_51S3olnLEcZxL3ukIwVaVl6RIa688W82Twb5t7vo2aYH0iB6VPQCeDlxvPsWRId3tNLZjfxQ0KFEa9mPnamPi0Ldx00PIMHn3If"
        print("Stripe initialized with publishable key.")

        return true
    }

    // MARK: - URL Handling for Deep Links

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        // Stripe Connect redirect (existing)
        if url.scheme == "rep" && url.host == "stripe-connect-return" {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let queryItems = components.queryItems,
               let portalIdString = queryItems.first(where: { $0.name == "portal_id" })?.value,
               let portalId = Int(portalIdString) {
                NotificationCenter.default.post(
                    name: Notification.Name("StripeConnectCompleted"),
                    object: nil,
                    userInfo: ["portal_id": portalId]
                )
                return true
            }
        }
        // Stripe Checkout payment success
        else if url.scheme == "rep" && url.host == "payment-success" {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let queryItems = components.queryItems,
               let sessionId = queryItems.first(where: { $0.name == "session_id" })?.value {
                NotificationCenter.default.post(
                    name: Notification.Name("PaymentCompleted"),
                    object: nil,
                    userInfo: ["session_id": sessionId, "status": "success"]
                )
                return true
            }
        }
        // Stripe Checkout payment canceled
        else if url.scheme == "rep" && url.host == "payment-canceled" {
            NotificationCenter.default.post(
                name: Notification.Name("PaymentCompleted"),
                object: nil,
                userInfo: ["status": "canceled"]
            )
            return true
        }
        else if url.scheme == "rep" && url.host == "payment-settings-return" {
            NotificationCenter.default.post(
                name: Notification.Name("PaymentSettingsCompleted"),
                object: nil
            )
            return true
        }
        return false
    }


    // MARK: - Remote Notifications

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("✅ Received APNS token")
        Messaging.messaging().apnsToken = deviceToken
        hasAPNSToken = true
        
        Messaging.messaging().token { fcmToken, error in
            if let fcmToken = fcmToken {
                print("✅ Successfully retrieved FCM token: \(fcmToken)")
                self.sendFCMTokenToBackend(fcmToken: fcmToken)
            } else if let error = error {
                print("❌ Error retrieving FCM token: \(error.localizedDescription)")
            }
        }
    }
    
    private func sendFCMTokenToBackend(fcmToken: String) {
        let jwtToken = UserDefaults.standard.string(forKey: "jwtToken") ?? ""
        let userId = UserDefaults.standard.integer(forKey: "userId")
        guard !jwtToken.isEmpty, userId > 0 else {
            print("No jwtToken or userId, not sending FCM token to backend.")
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
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["device_token": fcmToken])
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Failed to send FCM token to backend: \(error)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("FCM token sent to backend, status: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200, let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Backend response: \(responseString)")
                }
            }
        }.resume()
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let fcmToken = fcmToken {
            print("FCM registration token updated: \(fcmToken)")
            sendFCMTokenToBackend(fcmToken: fcmToken)
        }
    }
}

// MARK: - Notification Delegate

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse,
                               withCompletionHandler completionHandler: @escaping () -> Void) {
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
        if let data = onboardingProfileImageData { UIImage(data: data) } else { nil }
    }

    var sessionKey: String {
        "\(userId)-\(jwtToken)-\(isRegistered)-\(onboardingComplete)"
    }

    var body: some View {
        NavigationStack {
            if !isRegistered {
                RegisterNewProfileView()
            } else if !onboardingComplete {
                // Moved out to OnboardingView.swift
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