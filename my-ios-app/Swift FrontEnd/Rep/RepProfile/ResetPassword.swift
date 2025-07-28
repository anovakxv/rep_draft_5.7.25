//  ResetPassword.swift
//  Rep
//
//  Created by Adam Novak on 07.28.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.

import SwiftUI

struct ResetPasswordView: View {
    @State private var email: String = ""
    @State private var isSent: Bool = false
    @State private var isLoading: Bool = false
    @State private var error: String?
    @FocusState private var focusedField: Field?
    @Environment(\.dismiss) private var dismiss // <-- Add dismiss environment

    enum Field {
        case email
    }

    var body: some View {
        VStack(spacing: 32) {
            Text("Reset Password")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 32)

            if isSent {
                VStack(spacing: 16) {
                    Text("If an account exists for \(email), a reset link has been sent to your email.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    Button("Back to Login") {
                        dismiss() // <-- Actually dismisses the view
                    }
                    .padding(.top, 8)
                }
            } else {
                VStack(spacing: 16) {
                    TextField("Enter your email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .focused($focusedField, equals: .email)
                        .submitLabel(.done)
                        .onSubmit { sendReset() }

                    if let error = error {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }

                    Button(action: sendReset) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Send Reset Link")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(email.isEmpty || isLoading)
                    .frame(height: 54)
                    .background((email.isEmpty || isLoading) ? Color.gray.opacity(0.3) : Color.repGreen)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
            }

            Spacer()
        }
        .padding(24)
        .background(Color.white)
    }

    private func sendReset() {
        guard !email.isEmpty else { return }
        isLoading = true
        error = nil
        let url = URL(string: "\(APIConfig.baseURL)/api/user/forgot_password")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["email": email]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, err in
            DispatchQueue.main.async {
                isLoading = false
                if let err = err {
                    error = "Network error: \(err.localizedDescription)"
                    return
                }
                guard let data = data else {
                    error = "No response from server."
                    return
                }
                if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                    error = apiError.error
                } else {
                    // Assume success if no error
                    isSent = true
                }
            }
        }.resume()
    }
}

// --- Preview ---

struct ResetPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ResetPasswordView()
    }
}
