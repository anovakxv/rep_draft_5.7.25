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

    // --- Admin flag: Replace with your actual admin check logic ---
    @AppStorage("isAdmin") private var isAdmin: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Account")) {
                    Button {
                        showEditProfile = true
                    } label: {
                        HStack {
                            Image(systemName: "person.crop.circle")
                                .foregroundColor(Color(UIColor(red: 0.0, green: 0.4, blue: 0.0, alpha: 1.0))) // dark green
                            Text("Edit Profile")
                                .foregroundColor(Color(UIColor(red: 0.0, green: 0.4, blue: 0.0, alpha: 1.0))) // dark green
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
                                .foregroundColor(Color(UIColor(red: 0.0, green: 0.4, blue: 0.0, alpha: 1.0))) // dark green
                            Text("Payment & Payouts")
                                .foregroundColor(Color(UIColor(red: 0.0, green: 0.4, blue: 0.0, alpha: 1.0))) // dark green
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

                // --- Admin Tools Section ---
                if isAdmin {
                    Section(header: Text("Admin Tools")) {
                        NavigationLink {
                            StripeConnectApprovalView()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.seal")
                                    .foregroundColor(.blue)
                                Text("Approve Stripe Connect Accounts")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
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
            .navigationBarBackButtonHidden(true)
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack {
                            Image(systemName: "chevron.left")
                                .foregroundColor(Color(red: 0.549, green: 0.78, blue: 0.365)) 
                            Text("Back")
                                .foregroundColor(Color(red: 0.549, green: 0.78, blue: 0.365)) 
                        }
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.headline)
                        .foregroundColor(Color(UIColor(red: 0.0, green: 0.4, blue: 0.0, alpha: 1.0))) // dark green
                }
            }
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

struct StripeConnectApprovalView: View {
    @AppStorage("jwtToken") private var jwtToken: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var pendingAccounts: [PendingStripeAccount] = []
    @State private var showApproveSuccess: Bool = false

    var body: some View {
        VStack {
            Text("Stripe Connect Account Approvals")
                .font(.title2)
                .padding(.top)

            if isLoading {
                ProgressView("Loading...")
                    .padding()
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            } else if pendingAccounts.isEmpty {
                Text("No pending Stripe Connect accounts.")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List {
                    ForEach(pendingAccounts) { account in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(account.name)
                                .font(.headline)
                            Text("Portal ID: \(account.id)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            if let requestedAt = account.requestedAt {
                                Text("Requested: \(requestedAt)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Button("Approve") {
                                approveAccount(portalId: account.id)
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.top, 4)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .onAppear {
            fetchPendingAccounts()
        }
        .alert("Account Approved", isPresented: $showApproveSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Stripe Connect account approved successfully.")
        }
    }

    private func fetchPendingAccounts() {
        isLoading = true
        errorMessage = nil
        guard let url = URL(string: "\(APIConfig.baseURL)/api/admin/stripe_accounts/pending") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                guard let data = data else {
                    errorMessage = "No data received"
                    return
                }
                do {
                    let decoded = try JSONDecoder().decode([PendingStripeAccount].self, from: data)
                    pendingAccounts = decoded
                } catch {
                    errorMessage = "Failed to decode accounts: \(error.localizedDescription)"
                }
            }
        }.resume()
    }

    private func approveAccount(portalId: Int) {
        isLoading = true
        errorMessage = nil
        guard let url = URL(string: "\(APIConfig.baseURL)/api/admin/stripe_accounts/approve") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        let body: [String: Any] = ["portal_id": portalId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let status = json["status"] as? String, status == "approved" else {
                    errorMessage = "Failed to approve account"
                    return
                }
                showApproveSuccess = true
                // Remove the approved account from the list
                pendingAccounts.removeAll { $0.id == portalId }
            }
        }.resume()
    }
}

// Model for pending Stripe accounts
struct PendingStripeAccount: Identifiable, Codable {
    let id: Int
    let name: String
    let requestedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case requestedAt = "requested_at"
    }
}