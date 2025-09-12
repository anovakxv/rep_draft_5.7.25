//  Payments.swift
//  Rep
//
//  Created by Adam Novak on 9.4.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.

import SwiftUI
import StripePaymentSheet

struct PaymentsView: View {
    @StateObject private var viewModel = PaymentsViewModel()
    @State private var showCancelAlert = false
    @State private var subscriptionToCancel: ActiveSubscriptionItem?

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // --- Payments Manage Section ---
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Payment Settings")
                            .font(.title2).fontWeight(.bold)

                        Button(action: {
                            print("Manage Payments button tapped")
                            viewModel.openStripeCustomerPortal()
                        }) {
                            HStack {
                                Image(systemName: "creditcard")
                                Text("Manage Payments")
                                Spacer()
                            }
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(10)
                        }
                    }

                    // --- Active Subscriptions Section ---
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Active Subscriptions")
                            .font(.title2).fontWeight(.bold)

                        if viewModel.subscriptions.isEmpty && !viewModel.isLoading {
                            Text("You have no active monthly subscriptions.")
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(10)
                        } else {
                            ForEach(viewModel.subscriptions) { sub in
                                SubscriptionRowView(subscription: sub) {
                                    self.subscriptionToCancel = sub
                                    self.showCancelAlert = true
                                }
                            }
                        }
                    }

                    // --- Payment History Section ---
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Payment History")
                            .font(.title2).fontWeight(.bold)

                        if viewModel.history.isEmpty && !viewModel.isLoading {
                            Text("Your payment history will appear here.")
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(10)
                        } else {
                            ForEach(viewModel.history) { item in
                                TransactionHistoryRowView(item: item)
                            }
                        }
                    }
                }
                .padding()
            }
            .disabled(viewModel.isLoading)

            if viewModel.isLoading {
                ProgressView("Loading...")
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 8)
            }
        }
        .navigationTitle("Payments & Subscriptions")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadPaymentData()
            print("DIAGNOSTICS: jwtToken available: \(!viewModel.jwtToken.isEmpty)")

            // Listen for payment settings completion deep link
            NotificationCenter.default.addObserver(
                forName: Notification.Name("PaymentSettingsCompleted"),
                object: nil,
                queue: .main
            ) { _ in
                print("Received PaymentSettingsCompleted notification")
                viewModel.loadPaymentData()
            }
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(
                self,
                name: Notification.Name("PaymentSettingsCompleted"),
                object: nil
            )
        }
        .alert("Cancel Subscription?", isPresented: $showCancelAlert) {
            Button("Cancel Subscription", role: .destructive) {
                if let subId = subscriptionToCancel?.id {
                    viewModel.cancelSubscription(subscriptionId: subId)
                }
            }
            Button("Keep Subscription", role: .cancel) {}
        } message: {
            Text("Are you sure you want to cancel your \(subscriptionToCancel?.formattedAmount ?? "")/month subscription to \(subscriptionToCancel?.name ?? "")? This cannot be undone.")
        }
        .alert(item: $viewModel.errorMessage) { error in
            Alert(title: Text("Error"), message: Text(error), dismissButton: .default(Text("OK")))
        }
        .fullScreenCover(isPresented: $viewModel.showWebView) {
            NavigationView {
                if let url = viewModel.webViewURL {
                    SafariWebView(url: url, onDismiss: {
                        viewModel.showWebView = false
                    })
                    .navigationBarTitleDisplayMode(.inline)
                } else {
                    Text("Loading...")
                }
            }
        }
    }
}

// MARK: - ViewModel

class PaymentsViewModel: ObservableObject {
    @Published var subscriptions: [ActiveSubscriptionItem] = []
    @Published var history: [TransactionHistoryItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showWebView = false
    @Published var webViewURL: URL? = nil
    @AppStorage("jwtToken") var jwtToken: String = ""
    @AppStorage("userId") var userId: Int = 0

    func loadPaymentData() {
        isLoading = true
        let group = DispatchGroup()

        group.enter()
        fetchSubscriptions {
            group.leave()
        }

        group.enter()
        fetchHistory {
            group.leave()
        }

        group.notify(queue: .main) {
            self.isLoading = false
        }
    }

    func fetchSubscriptions(completion: @escaping () -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/subscriptions") else {
            completion()
            return
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            defer { completion() }
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                }
                return
            }
            guard let data = data else { return }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            if let decodedSubscriptions = try? decoder.decode([ActiveSubscriptionItem].self, from: data) {
                DispatchQueue.main.async {
                    self.subscriptions = decodedSubscriptions
                }
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to decode subscriptions"
                }
            }
        }.resume()
    }

    func fetchHistory(completion: @escaping () -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/payment_history") else {
            completion()
            return
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            defer { completion() }
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                }
                return
            }
            guard let data = data else { return }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            if let decodedHistory = try? decoder.decode([TransactionHistoryItem].self, from: data) {
                DispatchQueue.main.async {
                    self.history = decodedHistory
                }
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to decode payment history"
                }
            }
        }.resume()
    }

    func cancelSubscription(subscriptionId: String) {
        isLoading = true
        guard let url = URL(string: "\(APIConfig.baseURL)/api/cancel_subscription") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["subscriptionId": subscriptionId])

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    self.subscriptions.removeAll { $0.id == subscriptionId }
                } else {
                    self.errorMessage = "Failed to cancel subscription. Please try again."
                }
            }
        }.resume()
    }

    // MARK: - Stripe Flow Actions

    func openStripeCustomerPortal() {
        print("openStripeCustomerPortal called")
        print("userId: \(userId)")
        guard userId != 0 else {
            self.errorMessage = "No user ID found."
            print("No user ID found.")
            return
        }
        
        guard let url = URL(string: "\(APIConfig.baseURL)/api/create_customer_portal") else {
            print("Invalid URL for create_customer_portal")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "return_url": "rep://payment-settings-return"
        ])
        
        print("Sending Stripe customer portal API request to \(url)")
        URLSession.shared.dataTask(with: request) { data, response, error in
            print("Stripe customer portal API called")
            
            if let error = error {
                print("Error calling customer portal API: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data else {
                print("No data returned from customer portal API")
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("Customer portal API response:", json)
                
                if let portalURL = json["url"] as? String, let url = URL(string: portalURL) {
                    DispatchQueue.main.async {
                        self.webViewURL = url
                        self.showWebView = true
                        print("WebView should open with URL:", url)
                    }
                } else {
                    print("No URL in customer portal API response")
                    if let errorMessage = json["error"] as? String {
                        DispatchQueue.main.async {
                            self.errorMessage = errorMessage
                        }
                    }
                }
            } else {
                print("Failed to parse customer portal API response")
                DispatchQueue.main.async {
                    self.errorMessage = "Could not connect to payment system"
                }
            }
        }.resume()
    }
}

// MARK: - Data Models

struct ActiveSubscriptionItem: Identifiable, Codable {
    let id: String // Stripe Subscription ID
    let name: String // e.g., Portal Name or Goal Name
    let amount: Int // Amount in cents
    let nextBillingDate: Date

    var formattedAmount: String {
        String(format: "$%.2f", Double(amount) / 100)
    }
    var formattedNextBillingDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: nextBillingDate)
    }
}

struct TransactionHistoryItem: Identifiable, Codable {
    let id: String // Stripe Payment Intent ID
    let description: String
    let amount: Int // Amount in cents
    let date: Date

    var formattedAmount: String {
        String(format: "$%.2f", Double(amount) / 100)
    }
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Row Views

struct SubscriptionRowView: View {
    let subscription: ActiveSubscriptionItem
    var onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(subscription.name)
                    .font(.body).fontWeight(.semibold)
                Spacer()
                Text("\(subscription.formattedAmount)/mo")
                    .font(.body).fontWeight(.bold)
                    .foregroundColor(Color.repGreen)
            }
            Text("Next payment on \(subscription.formattedNextBillingDate)")
                .font(.caption)
                .foregroundColor(.secondary)
            Button("Cancel Subscription", role: .destructive, action: onCancel)
                .font(.caption)
                .padding(.top, 4)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
    }
}

struct TransactionHistoryRowView: View {
    let item: TransactionHistoryItem

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.description)
                    .font(.body)
                Text(item.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(item.formattedAmount)
                .font(.body).fontWeight(.semibold)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

struct PaymentsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PaymentsView()
        }
    }
}