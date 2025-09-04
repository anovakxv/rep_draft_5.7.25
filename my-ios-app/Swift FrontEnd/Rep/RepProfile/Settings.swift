//  Settings.swift
//  Rep
//
//  Created by Adam Novak on 9.4.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    // Session
    @AppStorage("jwtToken") private var jwtToken: String = ""
    @AppStorage("userId") private var userId: Int = 0

    // Edit Profile
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
    @Environment(\.dismiss) private var dismiss

    var body: some View {
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
                    PaymentSettingsView()
                } label: {
                    HStack {
                        Image(systemName: "creditcard")
                            .foregroundColor(.primary)
                        Text("Payment & Payouts")
                    }
                }
            }

            Section(header: Text("Notifications")) {
                // Placeholders; wire to your real toggles later
                Toggle(isOn: .constant(true)) {
                    Text("Push Notifications")
                }
                Toggle(isOn: .constant(true)) {
                    Text("Email Updates")
                }
            }

            Section(header: Text("Legal")) {
                Link(destination: URL(string: "https://yourdomain.com/terms")!) {
                    Text("Terms of Use")
                }
                Link(destination: URL(string: "https://yourdomain.com/privacy")!) {
                    Text("Privacy Policy")
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
        .onAppear {
            // Prefill profile info for Edit Profile flow (safe if already loaded)
            if userId > 0 {
                editProfileVM.fetchProfile(for: userId)
            }
        }
        .background(
            // Navigation to Edit Profile (kept local to Settings)
            NavigationLink(
                destination: EditProfileView(viewModel: editProfileVM),
                isActive: $showEditProfile
            ) { EmptyView() }
            .hidden()
        )
    }
}

// MARK: - Payment Settings (Stripe stub for now)
struct PaymentSettingsView: View {
    @State private var isLoading = false
    @State private var statusMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Text("Payments & Payouts")
                .font(.title2).bold()
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Connect your payment method and set up payouts. You’ll be able to submit and receive payments through Rep.")
                .frame(maxWidth: .infinity, alignment: .leading)

            // Placeholder buttons to be wired to Stripe
            Button {
                // TODO: Present Stripe PaymentSheet / Connect flow
                statusMessage = "Stripe setup coming soon."
            } label: {
                HStack {
                    Image(systemName: "link")
                    Text("Set Up Payments")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)

            Button {
                // TODO: Manage payout method via Stripe dashboard deep link
                statusMessage = "Open Stripe Dashboard (coming soon)."
            } label: {
                HStack {
                    Image(systemName: "arrow.up.right.square")
                    Text("Manage Payouts")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)

            if let msg = statusMessage {
                Text(msg).foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Payments")
        .navigationBarTitleDisplayMode(.inline)
    }
}
