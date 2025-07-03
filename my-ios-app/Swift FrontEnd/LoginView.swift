//
//  LoginView.swift
//  Rep 
//
//  Created by Dmytro Holovko on 04.12.2023.
//  Updated by Adam Novak on 06.19.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.

import SwiftUI
import Combine
import Dependiject

struct LoginView: View {
    @StateObject private var viewModel = APILoginViewModel()
    @State private var isAlertPresented = false
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case email, password
    }
    
    var body: some View {
        VStack {
            VStack {
                Spacer(minLength: 0)
                headerView
                Spacer(minLength: 0)
                VStack (spacing: 12.0) {
                    textFieldsView
                    forgotPasswordButton
                }
                Spacer()
                Spacer()
                Spacer()
                NavigationLink(destination: MainScreen(), isActive: $viewModel.isLoggedIn) { EmptyView() }
                NavigationLink(destination: SignUpView(), isActive: $viewModel.isSignUpPresented) { EmptyView() }
            }
            .padding(24)
            buttonsView
        }
        .toolbar(.hidden)
        .ignoresSafeArea(.keyboard)
        .onChange(of: viewModel.error) { _, newValue in
            isAlertPresented = newValue != nil
        }
        .alert(viewModel.error?.debugDescription ?? "", isPresented: $isAlertPresented) {
            Button("Ok", role: .cancel) { viewModel.error = nil }
        }
        .loading(isLoading: viewModel.isLoading)
        .background(Color.white)
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
            GTextField(model: .email, text: $viewModel.email)
                .focused($focusedField, equals: .email)
                .submitLabel(.next)
                .onSubmit { focusedField = .password }
            GTextField(model: .password, text: $viewModel.password)
                .focused($focusedField, equals: .password)
                .submitLabel(.go)
                .onSubmit { viewModel.login() }
        }
    }
    
    @ViewBuilder
    var forgotPasswordButton: some View {
        HStack {
            Spacer()
            Button("Forgot password?") {
                viewModel.forgotPassword()
            }
            .buttonStyle(.borderless)
            .accentColor(.repGreen)
            .font(.caption)
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
                Text("New User?")
                Button (action:{
                    viewModel.isSignUpPresented = true
                }, label: {
                    Text("Sign Up")
                })
                .buttonStyle(.borderless)
                .accentColor(.repGreen)
            }
        }
        .padding(24)
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
    @AppStorage("authToken") var authToken: String = ""

    func login() {
        guard !email.isEmpty && !password.isEmpty else {
            error = .inputDataError
            return
        }
        isLoading = true
        let url = URL(string: "http://localhost:5000/api/user/login")!
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
                    self.authToken = apiResult.token
                    self.isLoggedIn = true
                } else if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                    self.error = .serverError(apiError.error)
                } else {
                    self.error = .unknown
                }
            }
        }.resume()
    }

    func forgotPassword() {
        // Implement your forgot password logic here
        // For now, just show an error if email is empty
        guard !email.isEmpty else {
            error = .inputDataError
            return
        }
        // Example: Call your forgot password API here
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
    let email: String
    // Add other fields as needed
}

enum ServiceError: Error, CustomDebugStringConvertible {
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
}

extension Color {
    static let repGreen = Color(red: 0/255, green: 200/255, blue: 83/255)
}

#Preview