//  LoginView.swift
//  Rep
//
//  Created by Dmytro Holovko on 04.12.2023.
//  Updated by Adam Novak on 06.19.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.

import SwiftUI
import Combine
import FirebaseMessaging

// --- Custom Styled TextField for better placeholder and input readability ---
struct StyledLoginTextField: View {
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(Color(red: 0.35, green: 0.35, blue: 0.38)) // Darker gray
                    .font(.custom("Inter", size: 16))
                    .padding(.leading, 16)
            }
            if isSecure {
                SecureField("", text: $text)
                    .foregroundColor(.black)
                    .font(.custom("Inter", size: 16))
                    .padding(.leading, 16)
            } else {
                TextField("", text: $text)
                    .foregroundColor(.black)
                    .font(.custom("Inter", size: 16))
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
                    .padding(.leading, 16)
            }
        }
        .padding(.vertical, 12)
        .background(Color(red: 0.95, green: 0.95, blue: 0.95))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(red: 0.48, green: 0.75, blue: 0.29), lineWidth: 1)
        )
    }
}

// --- Stub Views for compilation ---

struct GTextField: View {
    enum Model { case email, password }
    let model: Model
    @Binding var text: String
    var body: some View {
        Group {
            if model == .password {
                SecureField("Password", text: $text)
                    .textContentType(.password)
            } else {
                TextField("Email", text: $text)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
            }
        }
        .autocapitalization(.none)
        .disableAutocorrection(true)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct GButton: View {
    let text: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.custom("Inter", size: 16).weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
        }
        .background(Color(red: 0.48, green: 0.75, blue: 0.29))
        .cornerRadius(14)
        .padding(.horizontal, 24)
    }
}

// --- Main LoginView ---

struct LoginView: View {
    @StateObject private var viewModel = APILoginViewModel()
    @State private var isAlertPresented = false
    @FocusState private var focusedField: Field?
    @State private var isResetPasswordPresented = false // <-- Added for reset password navigation

    enum Field: Hashable {
        case email, password
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                headerView
                    .padding(.bottom, 32)
                textFieldsView
                buttonsView
                Spacer()
                NavigationLink(destination: MainScreen(), isActive: $viewModel.isLoggedIn) { EmptyView() }
                NavigationLink(destination: RegisterNewProfileView(), isActive: $viewModel.isSignUpPresented) { EmptyView() }
                // --- Reset Password NavigationLink ---
                NavigationLink(destination: ResetPasswordView(), isActive: $isResetPasswordPresented) { EmptyView() }
            }
            .padding(24)
            .toolbar(.hidden)
            .ignoresSafeArea(.keyboard)
            .onChange(of: viewModel.error) { _, newValue in
                isAlertPresented = newValue != nil
            }
            .alert(viewModel.error?.debugDescription ?? "", isPresented: $isAlertPresented) {
                Button("Ok", role: .cancel) { viewModel.error = nil }
            }
            .background(Color.white)
        }
    }
            
    @ViewBuilder
    var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8.0) {
                Text("Welcome Back,")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Sign in to continue")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
    
    @ViewBuilder
    var textFieldsView: some View {
        VStack(spacing: 24.0) {
            StyledLoginTextField(
                placeholder: "Email",
                text: $viewModel.email,
                isSecure: false,
                keyboardType: .emailAddress,
                autocapitalization: .never // For email, use .never
            )
            .focused($focusedField, equals: .email)
            .submitLabel(.next)
            .onSubmit { focusedField = .password }
            StyledLoginTextField(
                placeholder: "Password",
                text: $viewModel.password,
                isSecure: true,
                keyboardType: .default,
                autocapitalization: .never // For password, use .never
            )
            .focused($focusedField, equals: .password)
            .submitLabel(.go)
            .onSubmit { viewModel.login() }
            // --- Add Reset Password Link ---
            HStack {
                Spacer()
                Button(action: {
                    isResetPasswordPresented = true
                }) {
                    Text("Forgot Password?")
                        .font(.footnote)
                        .foregroundColor(.blue)
                        .underline()
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    @ViewBuilder
    var buttonsView: some View {
        VStack(spacing: 24.0) {
            GButton(text: "Login") {
                viewModel.login()
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.email.isEmpty || viewModel.password.isEmpty)
            HStack {
                Text("New?")
                Button (action:{
                    viewModel.isSignUpPresented = true
                }, label: {
                    Text("Sign Up")
                        .font(.custom("Inter", size: 24).weight(.bold))
                })
                .buttonStyle(.borderless)
                .accentColor(SwiftUI.Color.repGreen)
            }
        }
        .padding(.top, 24)
        .font(.subheadline)
    }
}

class APILoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoggedIn = false
    @Published var isSignUpPresented = false
    @Published var isLoading = false
    @Published var error: ServiceError? = nil
    @AppStorage("userId") var userId: Int = 0
    @AppStorage("jwtToken") var jwtToken: String = ""
    @AppStorage("isRegistered") var isRegistered: Bool = false
    @AppStorage("onboardingComplete") var onboardingComplete: Bool = false 
    @AppStorage("isAdmin") var isAdmin: Bool = false

    func login() {
        guard !email.isEmpty && !password.isEmpty else {
            error = .inputDataError
            return
        }
        isLoading = true
        let url = URL(string: "\(APIConfig.baseURL)/api/user/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "email": email,
            "password": password
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, _, err in
            DispatchQueue.main.async {
                self.isLoading = false
                guard let data = data, err == nil else {
                    self.error = .networkError
                    return
                }
                if let apiResult = try? JSONDecoder().decode(LoginAPIResponse.self, from: data) {
                    self.userId = apiResult.result.id
                    self.jwtToken = apiResult.token
                    self.isRegistered = true
                    self.onboardingComplete = true // <-- CRITICAL: Mark onboarding as complete after login!
                    self.isLoggedIn = true

                    // --- Set isAdmin flag based on user_type ---
                    self.isAdmin = (apiResult.result.user_type == "Admin")

                    // --- Register FCM token after login ---
                    Messaging.messaging().token { token, error in
                        guard let token = token, !self.jwtToken.isEmpty, self.userId > 0 else { return }
                        guard let url = URL(string: "\(APIConfig.baseURL)/api/user/device_token") else { return }
                        var request = URLRequest(url: url)
                        request.httpMethod = "POST"
                        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                        request.setValue("Bearer \(self.jwtToken)", forHTTPHeaderField: "Authorization")
                        let body: [String: Any] = ["device_token": token]
                        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
                        URLSession.shared.dataTask(with: request) { _, response, _ in
                            if let httpResponse = response as? HTTPURLResponse {
                                print("FCM token sent to backend after login, status: \(httpResponse.statusCode)")
                            }
                        }.resume()
                    }
                    // --- End FCM registration ---

                } else if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                    self.error = .serverError(apiError.error)
                } else {
                    self.error = .unknown
                }
            }
        }.resume()
    }

    func forgotPassword() {
        // No longer used
    }
}

struct LoginAPIResponse: Decodable {
    let result: UserProfile
    let token: String
}

struct APIErrorResponse: Decodable {
    let error: String
}

struct UserProfile: Decodable {
    let id: Int
    let fname: String?
    let lname: String?
    let full_name: String?
    let username: String?
    let email: String?
    let about: String?
    let broadcast: String?
    let city: String?
    let created_at: String?
    let last_login: String?
    let last_message: String?
    let last_message_date: String?
    let profile_picture_url: String?
    let skills: [String]?
    let updated_at: String?
    let user_type: String?
}

enum ServiceError: Error, CustomDebugStringConvertible, Equatable {
    case inputDataError
    case networkError
    case serverError(String)
    case unknown

    var debugDescription: String {
        switch self {
        case .inputDataError:
            return "Please enter your email and password."
        case .networkError:
            return "Network error. Please try again."
        case .serverError(let message):
            return message
        case .unknown:
            return "An unknown error occurred."
        }
    }

    static func == (lhs: ServiceError, rhs: ServiceError) -> Bool {
        switch (lhs, rhs) {
        case (.inputDataError, .inputDataError),
             (.networkError, .networkError),
             (.unknown, .unknown):
            return true
        case (.serverError(let lMsg), .serverError(let rMsg)):
            return lMsg == rMsg
        default:
            return false
        }
    }
}
extension SwiftUI.Color {
    static let repGreen = SwiftUI.Color(red: 0/255, green: 200/255, blue: 83/255)
}

// --- Preview ---

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LoginView()
        }
    }
}