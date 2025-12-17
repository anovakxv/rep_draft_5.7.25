//  DonationDisclosureView.swift
//  Rep
//
//  Created by Adam Novak on 12.17.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.

import SwiftUI

struct DonationDisclosureView: View {
    let portalName: String
    let goalName: String
    let onAccept: () -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Donation Information")
                            .font(.title2.bold())
                            .foregroundColor(Color(red: 0.0, green: 0.4, blue: 0.0))

                        Text("Please read this important information before proceeding with your donation.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // Recipient Information
                    VStack(alignment: .leading, spacing: 12) {
                        Text("You are about to make a donation to:")
                            .font(.body)

                        Text(portalName)
                            .font(.title3.bold())
                            .foregroundColor(Color(red: 0.0, green: 0.4, blue: 0.0))

                        Text("For: \(goalName)")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)

                    // Tax Deductibility Warning
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.title3)
                            Text("Tax Deductibility Status")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }

                        Text("Rep does not verify the tax-exempt status of organizations on this platform. This donation may not be tax-deductible.")
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Please consult your tax advisor to determine if this donation qualifies for a tax deduction.")
                            .font(.body)
                            .fontWeight(.semibold)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange, lineWidth: 2)
                    )

                    // Payment Processing Information
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Payment Processing")
                            .font(.headline)

                        Text("Your donation will be processed securely through Stripe. You will be redirected to an external website to complete your donation.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)

                    Spacer(minLength: 20)

                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            dismiss()
                            onAccept()
                        }) {
                            Text("I Understand - Continue to Donation")
                                .font(.body.bold())
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(red: 0.0, green: 0.4, blue: 0.0))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }

                        Button(action: {
                            dismiss()
                            onCancel()
                        }) {
                            Text("Cancel")
                                .font(.body)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(UIColor.systemGray5))
                                .foregroundColor(.primary)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitle("Donation Disclosure", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                        onCancel()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                                .foregroundColor(Color(red: 0.549, green: 0.78, blue: 0.365))
                            Text("Back")
                                .foregroundColor(Color(red: 0.549, green: 0.78, blue: 0.365))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct DonationDisclosureView_Previews: PreviewProvider {
    static var previews: some View {
        DonationDisclosureView(
            portalName: "Community Food Bank",
            goalName: "Winter Food Drive 2025",
            onAccept: { print("Accepted") },
            onCancel: { print("Cancelled") }
        )
    }
}
