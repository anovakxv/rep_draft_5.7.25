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
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // --- Your Payment Methods Section ---
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your Payment Methods")
                            .font(.title2).fontWeight(.bold)

                        Button(action: {
                            viewModel.openStripeCustomerPortal()
                        }) {
                            HStack {
                                Image(systemName: "creditcard")
                                    .foregroundColor(Color(red: 0.0, green: 0.4, blue: 0.0))
                                Text("Edit Payment Methods")
                                    .foregroundColor(Color(red: 0.0, green: 0.4, blue: 0.0))
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundColor(Color(red: 0.0, green: 0.4, blue: 0.0))
                            }
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(10)
                        }
                        
                        Text("Your saved payment cards are used for your donations, payments, and subscriptions.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            
                        // Add explanation about personal payment information
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About Your Payment Information")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Text("Your payment information is securely stored with Stripe. You can add, remove, or update your payment cards at any time.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(10)
                        .padding(.top, 8)
                    }

                    // --- Payment Help Section ---
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Payment Support")
                            .font(.title2).fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Button(action: {
                                viewModel.openStripeSupport()
                            }) {
                                HStack {
                                    Image(systemName: "questionmark.circle")
                                        .foregroundColor(.blue)
                                    Text("Request Refund or Payment Help")
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square")
                                        .foregroundColor(.blue)
                                }
                                .padding()
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(10)
                            }
                            
                            Text("For payment disputes, refund requests, or other payment issues, contact Stripe support directly.")
                                .font(.caption)
                                .foregroundColor(.secondary)
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
                            
                            Text("You can cancel your subscriptions directly in the app. Changes take effect at the end of the current billing period.")
                                .font(.caption)
                                .foregroundColor(.secondary)
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
        .navigationBarBackButtonHidden(true)
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
        }
        .onAppear {
            viewModel.loadPaymentData()
            
            // Listen for payment settings completion deep link
            NotificationCenter.default.addObserver(
                forName: Notification.Name("PaymentSettingsCompleted"),
                object: nil,
                queue: .main
            ) { _ in
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
                    .navigationTitle(viewModel.webViewTitle)
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
    @Published var webViewTitle: String = ""
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
            
            // Debug: Print the raw JSON
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw subscriptions JSON: \(jsonString)")
            }
            
            let decoder = JSONDecoder()
            
            do {
                let decodedSubscriptions = try decoder.decode([ActiveSubscriptionItem].self, from: data)
                DispatchQueue.main.async {
                    self.subscriptions = decodedSubscriptions
                }
            } catch {
                print("Subscription decoding error: \(error)")
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to decode subscriptions: \(error.localizedDescription)"
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
        guard userId != 0 else {
            self.errorMessage = "No user ID found."
            return
        }
        
        guard let url = URL(string: "\(APIConfig.baseURL)/api/create_customer_portal") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "return_url": "rep://payment-settings-return"
        ])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data else { return }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let portalURL = json["url"] as? String, let url = URL(string: portalURL) {
                    DispatchQueue.main.async {
                        self.webViewTitle = "Stripe's Secure Website:"
                        self.webViewURL = url
                        self.showWebView = true
                    }
                } else if let errorMessage = json["error"] as? String {
                    DispatchQueue.main.async {
                        self.errorMessage = errorMessage
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Could not connect to payment system"
                }
            }
        }.resume()
    }
    
    // Function to open Stripe support for refunds and other issues
    func openStripeSupport() {
        // Direct link to Stripe support or help center
        if let url = URL(string: "https://support.stripe.com/") {
            DispatchQueue.main.async {
                self.webViewTitle = "Stripe's Support Website:"
                self.webViewURL = url
                self.showWebView = true
            }
        } else {
            self.errorMessage = "Could not open support page"
        }
    }
}

// MARK: - Data Models

struct ActiveSubscriptionItem: Identifiable, Codable {
    let id: String
    let name: String
    let amount: Int
    let nextBillingDate: Date

    enum CodingKeys: String, CodingKey {
        case id, name, amount, nextBillingDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        amount = try container.decode(Int.self, forKey: .amount)
        let timestamp = try container.decode(Int.self, forKey: .nextBillingDate)
        nextBillingDate = Date(timeIntervalSince1970: TimeInterval(timestamp))
    }

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
            // Text("Next payment on \(subscription.formattedNextBillingDate)")
            //    .font(.caption)
            //    .foregroundColor(.secondary)
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
            VStack(alignment: .leading, spacing: 2) {
                Text(item.description)
                    .font(.body)
                Text(item.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Stripe Transaction ID: \(item.id)")
                    .font(.caption2)
                    .foregroundColor(.gray)
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