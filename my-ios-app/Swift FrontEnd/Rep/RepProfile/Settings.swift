//  Settings.swift
//  Rep
//
//  Created by Adam Novak on 9.4.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("jwtToken") private var jwtToken: String = ""
    @AppStorage("userId") private var userId: Int = 0

    // Notification settings
    @AppStorage("pushNotificationsEnabled") private var pushNotificationsEnabled: Bool = true
    @AppStorage("notifDirectMessages") private var notifDirectMessages: Bool = true
    @AppStorage("notifGroupMessages") private var notifGroupMessages: Bool = true
    @AppStorage("notifGoalInvites") private var notifGoalInvites: Bool = true

    @StateObject private var editProfileVM = ProfileInfoViewModel(
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

    @State private var showEditProfile = false
    @State private var showTerms = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Account")) {
                    Button {
                        showEditProfile = true
                    } label: {
                        HStack {
                            Image(systemName: "person.crop.circle")
                                .foregroundColor(.primary)
                            Text("Edit Profile")
                        }
                    }
                    .buttonStyle(.plain)
                }

                Section(header: Text("Payments")) {
                    NavigationLink {
                        PaymentsView() // <-- Now navigates to your full Payments page!
                    } label: {
                        HStack {
                            Image(systemName: "creditcard")
                                .foregroundColor(.primary)
                            Text("Payment & Payouts")
                        }
                    }
                }

                Section(header: Text("Notifications")) {
                    Toggle("Push Notifications", isOn: $pushNotificationsEnabled)
                        .onChange(of: pushNotificationsEnabled) { enabled in
                            if enabled {
                                requestNotificationPermissions()
                            } else {
                                UIApplication.shared.unregisterForRemoteNotifications()
                            }
                            updateNotificationSettings()
                        }

                    if pushNotificationsEnabled {
                        Toggle("Direct Messages", isOn: $notifDirectMessages)
                            .onChange(of: notifDirectMessages) { _ in updateNotificationSettings() }

                        Toggle("Group Messages", isOn: $notifGroupMessages)
                            .onChange(of: notifGroupMessages) { _ in updateNotificationSettings() }

                        Toggle("Goal Team Invites", isOn: $notifGoalInvites)
                            .onChange(of: notifGoalInvites) { _ in updateNotificationSettings() }
                    }
                }

                Section(header: Text("Legal")) {
                    Button {
                        showTerms = true
                    } label: {
                        Text("Terms of Use")
                    }
                    .buttonStyle(.plain)
                }

                Section {
                    Button(role: .destructive) {
                        AuthSession.handleUnauthorized("SettingsView.logout")
                    } label: {
                        Text("Log Out")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if userId > 0 {
                    editProfileVM.fetchProfile(for: userId)
                }
            }
            .navigationDestination(isPresented: $showEditProfile) {
                EditProfileView(viewModel: editProfileVM)
            }
            .navigationDestination(isPresented: $showTerms) {
                TermsOfUseView()
            }
        }
    }

    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    private func updateNotificationSettings() {
        guard !jwtToken.isEmpty, userId > 0 else { return }

        let settings: [String: Bool] = [
            "pushNotificationsEnabled": pushNotificationsEnabled,
            "notifDirectMessages": notifDirectMessages,
            "notifGroupMessages": notifGroupMessages,
            "notifGoalInvites": notifGoalInvites
        ]

        guard let url = URL(string: "\(APIConfig.baseURL)/api/user/notification_settings") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONEncoder().encode(settings)

        URLSession.shared.dataTask(with: request) { _, _, _ in
            // No response handling needed for settings update
        }.resume()
    }
}