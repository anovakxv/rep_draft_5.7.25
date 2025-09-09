//  PortalPaymentSetup.swift
//  Rep
//
//  Created by Adam Novak on 09.08.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved

import SwiftUI
import WebKit

// MARK: - Portal Payment Setup View Model

class PortalPaymentViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var isConnected = false
    @Published var accountId: String? = nil
    @Published var showWebView = false
    @Published var webViewURL: URL? = nil
    
    let portalId: Int
    let portalName: String
    
    @AppStorage("jwtToken") private var jwtToken: String = ""
    
    init(portalId: Int, portalName: String) {
        self.portalId = portalId
        self.portalName = portalName
        checkConnectionStatus()
    }
    
    func checkConnectionStatus() {
        isLoading = true
        
        guard let url = URL(string: "\(APIConfig.baseURL)/api/portal/payment_status?portal_id=\(portalId)") else {
            self.errorMessage = "Invalid URL"
            self.isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Error checking payment status: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    self.errorMessage = "Invalid response from server"
                    return
                }
                
                if let accountId = json["stripe_account_id"] as? String, !accountId.isEmpty {
                    self.isConnected = true
                    self.accountId = accountId
                } else {
                    self.isConnected = false
                }
            }
        }.resume()
    }
    
    func createConnectAccount() {
        isLoading = true
        
        guard let url = URL(string: "\(APIConfig.baseURL)/api/create_connect_account") else {
            self.errorMessage = "Invalid URL"
            self.isLoading = false
            return
        }
        
        // Use the correct scheme (rep) for deep linking
        let redirectURL = "rep://stripe-connect-return?portal_id=\(portalId)"
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "portal_id": portalId,
            "redirect_url": redirectURL
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Error creating account: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let stripeURL = json["url"] as? String,
                      let url = URL(string: stripeURL) else {
                    self.errorMessage = "Invalid response from server"
                    return
                }
                
                if let accountId = json["account_id"] as? String {
                    self.accountId = accountId
                }
                
                self.webViewURL = url
                self.showWebView = true
            }
        }.resume()
    }
    
    func getStripeDashboardLink() {
        guard let accountId = accountId else {
            self.errorMessage = "No Stripe account found"
            return
        }
        
        isLoading = true
        
        guard let url = URL(string: "\(APIConfig.baseURL)/api/stripe_dashboard_link") else {
            self.errorMessage = "Invalid URL"
            self.isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "account_id": accountId
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Error getting dashboard link: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let dashboardURL = json["url"] as? String,
                      let url = URL(string: dashboardURL) else {
                    self.errorMessage = "Invalid response from server"
                    return
                }
                
                self.webViewURL = url
                self.showWebView = true
            }
        }.resume()
    }
    
    func handleWebViewDismiss() {
        showWebView = false
        webViewURL = nil
        // Check status again to see if connection was successful
        checkConnectionStatus()
    }
}

// MARK: - Safari WebView

struct SafariWebView: UIViewControllerRepresentable {
    let url: URL
    let onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> WKWebViewController {
        return WKWebViewController(url: url, onDismiss: onDismiss)
    }
    
    func updateUIViewController(_ webViewController: WKWebViewController, context: Context) {
        // No updates needed
    }
}

class WKWebViewController: UIViewController, WKNavigationDelegate {
    var webView: WKWebView!
    let url: URL
    let onDismiss: () -> Void
    
    init(url: URL, onDismiss: @escaping () -> Void) {
        self.url = url
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the WKWebView
        webView = WKWebView(frame: view.bounds)
        webView.navigationDelegate = self
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(webView)
        
        // Add close button
        let closeButton = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeWebView)
        )
        navigationItem.leftBarButtonItem = closeButton
        
        // Load the URL
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    @objc func closeWebView() {
        dismiss(animated: true) {
            self.onDismiss()
        }
    }
    
    // Handle redirect to our app scheme
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url, url.scheme == "rep" {
            // Handle the deep link - this is our success return URL
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            closeWebView()
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
}

// MARK: - Portal Payment Setup View

struct PortalPaymentSetup: View {
    @StateObject private var viewModel: PortalPaymentViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(portalId: Int, portalName: String) {
        _viewModel = StateObject(wrappedValue: PortalPaymentViewModel(portalId: portalId, portalName: portalName))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    Text("Payment Settings")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Set up your portal to receive payments")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom)
                
                // Status Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: viewModel.isConnected ? "checkmark.circle.fill" : "exclamationmark.circle")
                            .foregroundColor(viewModel.isConnected ? .green : .orange)
                            .font(.title2)
                        
                        Text(viewModel.isConnected ? "Connected to Stripe" : "Not Connected to Stripe")
                            .font(.headline)
                        
                        Spacer()
                    }
                    
                    Text(viewModel.isConnected ? 
                        "Your portal is connected to Stripe and can receive payments. You can manage your account through the Stripe Dashboard." : 
                        "Connect your portal to Stripe to receive donations, payments, and purchases from users.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if viewModel.isConnected {
                        Button(action: {
                            viewModel.getStripeDashboardLink()
                        }) {
                            HStack {
                                Image(systemName: "arrow.up.right.square")
                                Text("Go to Stripe Dashboard")
                                Spacer()
                            }
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                        }
                    } else {
                        Button(action: {
                            viewModel.createConnectAccount()
                        }) {
                            HStack {
                                Image(systemName: "link")
                                Text("Connect to Stripe")
                                Spacer()
                            }
                            .padding()
                            .background(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)
                
                // Payment Info
                VStack(alignment: .leading, spacing: 16) {
                    Text("About Payments")
                        .font(.headline)
                    
                    InfoRow(icon: "creditcard", title: "Secure Payments", description: "All payments are securely processed by Stripe, a PCI-compliant payment processor.")
                    
                    InfoRow(
                        icon: "dollarsign.circle",
                        title: "Transaction Fee",
                        description: """
                    Rep does not charge any additional platform fee. Stripe’s standard rates apply. For example: 2.9% + 30¢ per successful transaction for domestic cards, 0.8% for ACH Direct Debit. For full details, see stripe.com/pricing.
                    """
                    )
                    
                    InfoRow(icon: "calendar", title: "Payouts", description: "Funds will be directly deposited to your bank account based on your Stripe payout schedule.")
                    
                    InfoRow(icon: "doc.text", title: "Tax Information", description: "You'll need to provide tax information in your Stripe account to receive payments.")
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .padding()
            .disabled(viewModel.isLoading)
            .overlay(
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                    }
                }
            )
        }
        .navigationTitle("Payment Setup")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $viewModel.showWebView) {
            NavigationView {
                if let url = viewModel.webViewURL {
                    SafariWebView(url: url, onDismiss: {
                        viewModel.handleWebViewDismiss()
                    })
                    .ignoresSafeArea()
                    .navigationBarTitleDisplayMode(.inline)
                } else {
                    Text("Loading...")
                }
            }
        }
        .onAppear {
            viewModel.checkConnectionStatus()
            
            // Listen for Stripe Connect completion
            NotificationCenter.default.addObserver(
                forName: Notification.Name("StripeConnectCompleted"),
                object: nil,
                queue: .main
            ) { notification in
                if let portalId = notification.userInfo?["portal_id"] as? Int,
                   portalId == viewModel.portalId {
                    viewModel.checkConnectionStatus()
                }
            }
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(
                self,
                name: Notification.Name("StripeConnectCompleted"),
                object: nil
            )
        }
    }
}

// MARK: - Supporting Views

struct InfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.primary)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Preview

struct PortalPaymentSetup_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PortalPaymentSetup(portalId: 1, portalName: "Community Garden Project")
        }
    }
}
