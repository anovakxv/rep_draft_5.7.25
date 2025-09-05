//  Payments.swift
//  Rep
//
//  Created by Adam Novak on 9.4.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.

import SwiftUI
import StripePaymentSheet

struct PaymentsView: View {
    @State private var isLoading = false
    @State private var message: String?
    @State private var paymentSheet: PaymentSheet?
    @AppStorage("jwtToken") private var jwtToken: String = ""
    @State private var showingSheet = false

    // For showing saved payment methods (optional, can be implemented later)
    @State private var savedPaymentMethods: [PaymentMethod] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Your Payment Methods")
                    .font(.title2).bold()
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Add a payment method to your account to easily pay for services or make donations. All payment info is securely handled by Stripe.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Show saved payment methods if available
                if !savedPaymentMethods.isEmpty {
                    ForEach(savedPaymentMethods, id: \.id) { method in
                        PaymentMethodRow(method: method, isDefault: method.isDefault)
                    }
                }

                Button {
                    isLoading = true
                    preparePaymentSheet()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Add Payment Method")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.549, green: 0.78, blue: 0.365)) // RepGreen
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isLoading)

                if let message = message {
                    Text(message)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Payment Methods")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Optionally load saved payment methods here
            // loadSavedPaymentMethods()
        }
    }

    private func preparePaymentSheet() {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/create_setup_intent") else {
            message = "Invalid URL"
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            isLoading = false

            guard let data = data, error == nil,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let clientSecret = json["clientSecret"] as? String else {
                message = "Failed to prepare payment method"
                return
            }

            DispatchQueue.main.async {
                var configuration = PaymentSheet.Configuration()
                configuration.merchantDisplayName = "Rep App"
                configuration.allowsDelayedPaymentMethods = false

                paymentSheet = PaymentSheet(
                    setupIntentClientSecret: clientSecret,
                    configuration: configuration
                )

                presentPaymentSheet()
            }
        }.resume()
    }

    private func presentPaymentSheet() {
        guard let paymentSheet = paymentSheet else { return }
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            message = "Unable to present payment sheet"
            return
        }
        paymentSheet.present(from: rootVC) { result in
            switch result {
            case .completed:
                message = "Payment method added successfully"
                // Optionally reload saved payment methods here
            case .canceled:
                message = "Canceled"
            case .failed(let error):
                message = "Error: \(error.localizedDescription)"
            }
        }
    }
}

// Simple model for payment methods (optional, for future use)
struct PaymentMethod: Identifiable, Codable {
    let id: String
    let last4: String
    let brand: String
    let isDefault: Bool
}

struct PaymentMethodRow: View {
    let method: PaymentMethod
    let isDefault: Bool

    var body: some View {
        HStack {
            Image(systemName: "creditcard")
                .foregroundColor(.primary)

            VStack(alignment: .leading) {
                Text("\(method.brand) •••• \(method.last4)")
                    .font(.body)
                if isDefault {
                    Text("Default")
                        .font(.caption)
                        .foregroundColor(Color(red: 0.549, green: 0.78, blue: 0.365)) // RepGreen
                }
            }

            Spacer()

            // More actions menu (optional, for future use)
            Menu {
                Button("Set as Default") {
                    // Call API to set as default
                }

                Button("Remove", role: .destructive) {
                    // Call API to remove
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
    }
}