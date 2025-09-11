//  PayTransaction.swift
//  Rep
//
//  Created by Adam Novak: Sept. 2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.

import SwiftUI

// MARK: - Transaction Types

enum TransactionType {
    case donation
    case payment
    case purchase

    var title: String {
        switch self {
        case .donation: return "Donate"
        case .payment: return "Pay"
        case .purchase: return "Purchase"
        }
    }

    var subtitle: String {
        switch self {
        case .donation: return "Your contribution helps this organization achieve its goals"
        case .payment: return "Your payment helps fund this business initiative"
        case .purchase: return "Complete your purchase to support this business"
        }
    }

    var amountLabel: String {
        switch self {
        case .donation: return "Donation Amount"
        case .payment: return "Payment Amount"
        case .purchase: return "Total Amount"
        }
    }

    var messageLabel: String {
        switch self {
        case .donation: return "Message (Optional)"
        case .payment: return "Notes for Recipient (Optional)"
        case .purchase: return "Order Notes (Optional)"
        }
    }

    var ctaText: String {
        switch self {
        case .donation: return "Donate"
        case .payment: return "Pay"
        case .purchase: return "Complete Purchase"
        }
    }

    var receiptTitle: String {
        switch self {
        case .donation: return "Thank You for Your Donation!"
        case .payment: return "Payment Complete"
        case .purchase: return "Purchase Successful"
        }
    }

    var receiptMessage: String {
        switch self {
        case .donation: return "Your donation has been processed successfully."
        case .payment: return "Your payment has been processed successfully."
        case .purchase: return "Your purchase has been completed successfully."
        }
    }
}

// MARK: - Main Transaction View

struct PayTransactionView: View {
    let portalId: Int
    let portalName: String
    let goalId: Int
    let goalName: String
    let transactionType: TransactionType

    let monthlyPriceOptions: [(amount: Int, priceId: String)] = [
        (10, "price_1S5Z8lLEcZxL3ukI6dh5l5PM"),   // $10/month
        (20, "price_1S5Z9GLEcZxL3ukI9LcKmj0P"),   // $20/month
        (40, "price_1S5Z9bLEcZxL3ukIrn8LjNGl"),   // $40/month
        (100, "price_1S5Z9zLEcZxL3ukItz2JikK5")   // $100/month
    ]

    @State private var amount: String = ""
    @State private var message: String = ""
    @State private var isLoading = false
    @State private var paymentStatus: PaymentStatus = .initial
    @State private var isMonthlySubscription = false
    @State private var selectedPriceId: String = ""
    @AppStorage("jwtToken") private var jwtToken: String = ""
    @Environment(\.dismiss) private var dismiss

    // MARK: - Payment Status

    enum PaymentStatus {
        case initial, loading, success, failed(String)
    }

    // MARK: - Main View

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header section
                    VStack(spacing: 8) {
                        Text("\(transactionType.title) to \(portalName)")
                            .font(.title2.bold())

                        if !goalName.isEmpty {
                            Text("For: \(goalName)")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                        }

                        Text(transactionType.subtitle)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.bottom)
                    }
                    .padding(.horizontal)

                    // Amount entry
                    VStack(alignment: .leading, spacing: 8) {
                        Text(transactionType.amountLabel).font(.headline)

                        HStack {
                            Text("$").font(.title3)
                            TextField("0.00", text: $amount)
                                .keyboardType(.decimalPad)
                                .font(.title)
                                .disabled(isMonthlySubscription) // Disable manual entry for subscriptions
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)

                        // Quick amounts (customizable per transaction type)
                        if !isMonthlySubscription {
                            quickAmountsView
                        }
                    }
                    .padding(.horizontal)

                    // Monthly subscription toggle and options
                    Toggle("Make this a monthly recurring payment", isOn: $isMonthlySubscription)
                        .padding(.horizontal)

                    if isMonthlySubscription {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Choose your monthly amount:")
                                .font(.headline)
                            HStack {
                                ForEach(monthlyPriceOptions, id: \.amount) { option in
                                    Button("$\(option.amount)") {
                                        selectedPriceId = option.priceId
                                        amount = "\(option.amount)"
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedPriceId == option.priceId ? Color.repGreen : Color(UIColor.systemGray5))
                                    .foregroundColor(selectedPriceId == option.priceId ? .white : .black)
                                    .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Optional message
                    VStack(alignment: .leading, spacing: 8) {
                        Text(transactionType.messageLabel).font(.headline)
                        TextEditor(text: $message)
                            .frame(height: 44)
                            .padding(4)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)

                    if case .failed(let error) = paymentStatus {
                        Text(error)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }

                    // Safari-based Stripe Checkout button
                    Button {
                        guard validateAmount() else { return }
                        isLoading = true
                        createCheckoutSession()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(isMonthlySubscription
                                ? "Subscribe $\(formattedAmount)/mo"
                                : "\(transactionType.ctaText) $\(formattedAmount)")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.repGreen)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(isLoading || amount.isEmpty || (isMonthlySubscription && selectedPriceId.isEmpty))
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Info about Safari redirect
                    Text("You'll be redirected to a secure payment page to complete your \(isMonthlySubscription ? "subscription" : transactionType.title.lowercased()).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // If it's a donation, add a tax info note
                    if transactionType == .donation {
                        Text("Your donation may be tax deductible. A receipt will be emailed to you.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.vertical)
            }
            .navigationBarTitle(transactionType.title, displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert(isPresented: Binding<Bool>(
                get: { isSuccess },
                set: { if !$0 { paymentStatus = .initial } }
            )) {
                Alert(
                    title: Text(transactionType.receiptTitle),
                    message: Text(transactionType.receiptMessage),
                    dismissButton: .default(Text("Done")) {
                        dismiss()
                    }
                )
            }
            .onAppear {
                NotificationCenter.default.addObserver(
                    forName: Notification.Name("PaymentCompleted"),
                    object: nil,
                    queue: .main
                ) { notification in
                    if let status = notification.userInfo?["status"] as? String {
                        if status == "success" {
                            if let sessionId = notification.userInfo?["session_id"] as? String {
                                self.checkPaymentStatus(sessionId: sessionId)
                            } else {
                                self.paymentStatus = .success
                            }
                        } else if status == "canceled" {
                            self.paymentStatus = .initial
                        }
                    }
                }
            }
            .onDisappear {
                NotificationCenter.default.removeObserver(
                    self,
                    name: Notification.Name("PaymentCompleted"),
                    object: nil
                )
            }
        }
    }

    // MARK: - Quick Amount View

    @ViewBuilder
    private var quickAmountsView: some View {
        switch transactionType {
        case .donation:
            HStack {
                ForEach([5, 10, 25, 50], id: \.self) { value in
                    quickAmountButton(value)
                }
            }
        case .payment:
            HStack {
                ForEach([20, 50, 100, 200], id: \.self) { value in
                    quickAmountButton(value)
                }
            }
        case .purchase:
            HStack {
                ForEach([25, 50, 75, 100], id: \.self) { value in
                    quickAmountButton(value)
                }
            }
        }
    }

    private func quickAmountButton(_ value: Int) -> some View {
        Button("$\(value)") {
            amount = "\(value)"
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(UIColor.systemGray5))
        .cornerRadius(16)
    }

    // MARK: - Helper Functions

    private var formattedAmount: String {
        guard let amountValue = Double(amount) else { return "0.00" }
        return String(format: "%.2f", amountValue)
    }

    private func validateAmount() -> Bool {
        if isMonthlySubscription {
            if selectedPriceId.isEmpty {
                paymentStatus = .failed("Please select a monthly amount.")
                return false
            }
            return true
        }
        guard let amountValue = Double(amount),
              amountValue >= 1.0 else {
            paymentStatus = .failed("Please enter a valid amount (minimum $1.00)")
            return false
        }
        return true
    }

    // MARK: - Stripe Checkout Session (Safari-based)

    private func createCheckoutSession() {
        paymentStatus = .loading

        guard let url = URL(string: "\(APIConfig.baseURL)/api/create_checkout_session") else {
            paymentStatus = .failed("Invalid URL")
            isLoading = false
            return
        }

        guard let amountValue = Double(amount),
              amountValue > 0 || isMonthlySubscription else {
            paymentStatus = .failed("Invalid amount")
            isLoading = false
            return
        }

        // Convert to cents
        let amountCents = Int(amountValue * 100)

        var requestBody: [String: Any] = [
            "portal_id": portalId,
            "goal_id": goalId,
            "currency": "usd",
            "message": message,
            "transaction_type": transactionTypeString
        ]

        if isMonthlySubscription {
            requestBody["is_subscription"] = true
            requestBody["price_id"] = selectedPriceId
        } else {
            requestBody["amount"] = amountCents
            requestBody["is_subscription"] = false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false

                if let error = error {
                    self.paymentStatus = .failed("Network error: \(error.localizedDescription)")
                    return
                }

                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let checkoutUrl = json["checkout_url"] as? String,
                      let url = URL(string: checkoutUrl) else {
                    self.paymentStatus = .failed("Failed to create checkout session")
                    return
                }

                // Save session_id for status check after return
                if let sessionId = json["session_id"] as? String {
                    UserDefaults.standard.set(sessionId, forKey: "lastCheckoutSessionId")
                }

                // Open Safari to complete payment
                if let checkoutUrl = json["checkout_url"] as? String,
                    let url = URL(string: checkoutUrl) {
                        print("Attempting to open checkout URL: \(checkoutUrl)")
                        DispatchQueue.main.async {
                            UIApplication.shared.open(url, options: [:]) { success in
                                if !success {
                                    print("Failed to open URL with options, trying openURL...")
                                    if #available(iOS 10.0, *) {
                                        UIApplication.shared.open(url)
                                    } else {
                                        UIApplication.shared.openURL(url)
                                    }
                                }
                            }
                        }
                    }
            }
        }.resume()
    }

    private func checkPaymentStatus(sessionId: String) {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/checkout_session_status?session_id=\(sessionId)") else {
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let paymentStatus = json["payment_status"] as? String {

                    if paymentStatus == "paid" {
                        self.paymentStatus = .success
                    } else if paymentStatus == "unpaid" {
                        self.paymentStatus = .failed("Payment was not completed")
                    }
                } else {
                    self.paymentStatus = .initial
                }
            }
        }.resume()
    }

    private var transactionTypeString: String {
        switch transactionType {
        case .donation: return "donation"
        case .payment: return "payment"
        case .purchase: return "purchase"
        }
    }

    private var isSuccess: Bool {
        if case .success = paymentStatus { return true }
        return false
    }
}

// MARK: - Preview

struct PayTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PayTransactionView(
                portalId: 1,
                portalName: "Save the Whales",
                goalId: 2,
                goalName: "Annual Fundraiser",
                transactionType: .donation
            )
            .previewDisplayName("Donation")

            PayTransactionView(
                portalId: 3,
                portalName: "Tech Startup Inc.",
                goalId: 4,
                goalName: "Product Development",
                transactionType: .payment
            )
            .previewDisplayName("Payment")

            PayTransactionView(
                portalId: 5,
                portalName: "Artisan Goods Co.",
                goalId: 6,
                goalName: "Limited Edition Products",
                transactionType: .purchase
            )
            .previewDisplayName("Purchase")
        }
    }
}