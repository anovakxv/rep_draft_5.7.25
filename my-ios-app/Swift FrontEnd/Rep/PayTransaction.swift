//  PayTransaction.swift
//  Rep
//
//  Created by Adam Novak: Sept. 2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.

import SwiftUI
import WebKit

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
        (5, "price_1S8BJNLEcZxL3ukIiYVOMyHD"),   // $5/month
        (10, "price_1S8BJeLEcZxL3ukI3fpsE25j"),   // $10/month
        (20, "price_1S8BJuLEcZxL3ukIwJshQJp6"),   // $20/month
        (40, "price_1S8BK9LEcZxL3ukISu3iPeLK")   // $40/month
    ]

    @State private var amount: String = ""
    @State private var message: String = ""
    @State private var isLoading = false
    @State private var paymentStatus: PaymentStatus = .initial
    @State private var isMonthlySubscription = false
    @State private var selectedPriceId: String = ""
    @State private var showPaymentSetupAlert = false
    @State private var showPaymentErrorAlert = false
    @State private var paymentErrorMessage: String = ""
    @State private var showSuccessBanner = false
    @AppStorage("jwtToken") private var jwtToken: String = ""
    @Environment(\.dismiss) private var dismiss

    // For Stripe Checkout WebView
    @State private var showWebView = false
    @State private var webViewURL: URL? = nil
    @State private var webViewTitle: String = ""

    @State private var showMonthlyNotAvailableAlert = false

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
                            .foregroundColor(Color(UIColor(red: 0.0, green: 0.4, blue: 0.0, alpha: 1.0))) // dark green

                        if !goalName.isEmpty {
                            Text("For: \(goalName)")
                                .font(.headline)
                                .foregroundColor(Color(UIColor(red: 0.0, green: 0.4, blue: 0.0, alpha: 1.0))) 
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
                                .disabled(isMonthlySubscription)
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)

                        if !isMonthlySubscription {
                            quickAmountsView
                        }
                    }
                    .padding(.horizontal)

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

                    // Stripe Checkout button (now opens in-app web view)
                    Button(action: {
                        guard validateAmount() else { return }
                        isLoading = true
                        createCheckoutSession()
                    }) {
                        ZStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text(isMonthlySubscription
                                    ? "Subscribe $\(formattedAmount)/mo"
                                    : "\(transactionType.ctaText) $\(formattedAmount)")
                                    .frame(maxWidth: .infinity)
                            }
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

                    Text("Payment info is handled directly through Stripe, a secure online payments platform. You'll be redirected to a secure payment page to complete your \(isMonthlySubscription ? "subscription" : transactionType.title.lowercased()).")
                        .font(.body) // Increased font size
                        .foregroundColor(.black) // Black text
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    if transactionType == .donation {
                        Text("If your payment is a donation, it may be tax deductible. A receipt will be emailed to you.")
                            .font(.body) // Increased font size
                            .foregroundColor(.black) // Black text
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
                                .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0))) // light green
                            Text("Back")
                                .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0))) // light green
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0))) // light green
                }
            }
            .alert(isPresented: $showPaymentErrorAlert) {
                Alert(
                    title: Text("Payment Error"),
                    message: Text(paymentErrorMessage),
                    dismissButton: .default(Text("OK")) {
                        paymentStatus = .initial
                    }
                )
            }
            .alert(isPresented: $showPaymentSetupAlert) {
                Alert(
                    title: Text("Payments Not Ready"),
                    message: Text("This organization hasn't completed their payment setup yet and cannot receive payments at this time."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                NotificationCenter.default.addObserver(
                    forName: Notification.Name("PaymentCompleted"),
                    object: nil,
                    queue: .main
                ) { notification in
                    #if DEBUG
                    print("[PayTransactionView] Received PaymentCompleted notification:", notification.userInfo ?? [:])
                    #endif
                    if let status = notification.userInfo?["status"] as? String {
                        if status == "success" {
                            if let sessionId = notification.userInfo?["session_id"] as? String {
                                self.checkPaymentStatus(sessionId: sessionId)
                            } else {
                                self.paymentStatus = .success
                                self.showSuccessBanner = true
                                // Auto-dismiss after showing banner
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                    self.showSuccessBanner = false
                                    self.dismiss()
                                }
                            }
                        } else if status == "canceled" {
                            self.paymentStatus = .failed("Payment was canceled or not completed.")
                            self.paymentErrorMessage = "Payment was canceled or not completed."
                            self.showPaymentErrorAlert = true
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
            .fullScreenCover(isPresented: $showWebView) {
                NavigationView {
                    if let url = webViewURL {
                        SafariWebView(url: url, onDismiss: {
                            self.showWebView = false
                        })
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationTitle(webViewTitle)
                    } else {
                        Text("Loading...")
                    }
                }
            }
            .overlay(
                Group {
                    if showSuccessBanner {
                        VStack {
                            Spacer()
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(red: 0.0, green: 0.4, blue: 0.0))
                                    .font(.system(size: 28))
                                Text(transactionType.receiptTitle)
                                    .font(.title3.bold())
                                    .foregroundColor(Color(red: 0.0, green: 0.4, blue: 0.0))
                                    .padding(.vertical, 8)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 2)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 40)
                            .zIndex(100)
                        }
                        .opacity(showSuccessBanner ? 1 : 0) // <-- Simple opacity, no animation context leak
                    }
                }
            )
        }
    }

    // MARK: - Quick Amount View

    @ViewBuilder
    private var quickAmountsView: some View {
        switch transactionType {
        case .donation:
            HStack {
                ForEach([10, 20, 50, 100], id: \.self) { value in
                    quickAmountButton(value)
                }
            }
        case .payment:
            HStack {
                ForEach([10, 20, 50, 100], id: \.self) { value in
                    quickAmountButton(value)
                }
            }
        case .purchase:
            HStack {
                ForEach([10, 20, 50, 100], id: \.self) { value in
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
        .foregroundColor(Color(UIColor(red: 0.0, green: 0.4, blue: 0.0, alpha: 1.0))) // dark green
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

    // MARK: - Stripe Checkout Session (In-app WebView)

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
                    self.paymentErrorMessage = "Network error: \(error.localizedDescription)"
                    self.showPaymentErrorAlert = true
                    self.paymentStatus = .failed("Network error: \(error.localizedDescription)")
                    return
                }

                guard let data = data,
                    let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    self.paymentErrorMessage = "Failed to create checkout session"
                    self.showPaymentErrorAlert = true
                    self.paymentStatus = .failed("Failed to create checkout session")
                    return
                }

                if let errorMsg = json["error"] as? String {
                    // Check for any payment setup issues
                    if errorMsg.contains("Portal not set up to receive payments") || 
                        errorMsg.contains("account is not fully onboarded") ||
                        errorMsg.contains("account is not activated") ||
                        errorMsg.contains("charges_enabled") ||
                        errorMsg.contains("transfers_enabled") ||
                        errorMsg.contains("missing the required capabilities") || // Add this line
                        errorMsg.contains("required capabilities: transfers") {   // Add this line
                        self.showPaymentSetupAlert = true
                    } else {
                        self.paymentErrorMessage = errorMsg
                        self.showPaymentErrorAlert = true
                        self.paymentStatus = .failed(errorMsg)
                    }
                    return
                }

                guard let checkoutUrl = json["checkout_url"] as? String,
                    let url = URL(string: checkoutUrl) else {
                    self.paymentErrorMessage = "Failed to create checkout session"
                    self.showPaymentErrorAlert = true
                    self.paymentStatus = .failed("Failed to create checkout session")
                    return
                }

                if let sessionId = json["session_id"] as? String {
                    UserDefaults.standard.set(sessionId, forKey: "lastCheckoutSessionId")
                }

                // Present Stripe Checkout in-app web view
                self.webViewURL = url
                self.webViewTitle = "Stripe's Secure Website:"
                self.showWebView = true
            }
        }.resume()
    }

    private func checkPaymentStatus(sessionId: String) {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/checkout_session_status?session_id=\(sessionId)") else {
            // Show success banner and dismiss
            self.paymentStatus = .success
            self.showSuccessBanner = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                self.showSuccessBanner = false
                self.dismiss()
            }
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let data = data,
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let paymentStatus = json["payment_status"] as? String {

                    #if DEBUG
                    print("[PayTransactionView] checkPaymentStatus response:", paymentStatus)
                    #endif

                    if paymentStatus == "paid" {
                        self.paymentStatus = .success
                        // Show success banner and dismiss
                        self.showSuccessBanner = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            self.showSuccessBanner = false
                            self.dismiss()
                        }
                    } else if paymentStatus == "unpaid" {
                        self.paymentStatus = .failed("Payment was not completed")
                        self.paymentErrorMessage = "Payment was not completed"
                        self.showPaymentErrorAlert = true
                    }
                } else {
                    // Fallback: assume success if we got here after a success notification
                    #if DEBUG
                    print("[PayTransactionView] checkPaymentStatus decode failed, assuming success")
                    #endif
                    self.paymentStatus = .success
                    // Show success banner and dismiss
                    self.showSuccessBanner = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        self.showSuccessBanner = false
                        self.dismiss()
                    }
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
}