//  Settings.swift
//  Rep
//
//  Created by Adam Novak on 9.4.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("jwtToken") private var jwtToken: String = ""
    @AppStorage("userId") private var userId: Int = 0

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
                    Toggle(isOn: .constant(true)) {
                        Text("Push Notifications")
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