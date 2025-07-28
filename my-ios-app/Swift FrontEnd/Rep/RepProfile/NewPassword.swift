//  NewPassword.swift
//  Rep
//
//  Created by Adam Novak on 07.28.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.

import SwiftUI

struct NewPasswordView: View {
    let resetToken: String

    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isLoading: Bool = false
    @State private var error: String?
    @State private var isSuccess: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 32) {
            Text("Set New Password")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 32)

            if isSuccess {
                VStack(spacing: 16) {
                    Text("Your password has been reset successfully.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    Button("Back to Login") {
                        dismiss()
                    }
                    .padding(.top, 8)
                }
            } else {
                VStack(spacing: 16) {
                    SecureField("New Password", text: $newPassword)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)

                    SecureField("Confirm Password", text: $confirmPassword)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)

                    if let error = error {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }

                    Button(action: setNewPassword) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Set Password")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(newPassword.isEmpty || confirmPassword.isEmpty || isLoading)
                    .frame(height: 54)
                    .background((newPassword.isEmpty || confirmPassword.isEmpty || isLoading) ? Color.gray.opacity(0.3) : Color.repGreen)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
            }

            Spacer()
        }
        .padding(24)
        .background(Color.white)
    }

    private func setNewPassword() {
        guard !newPassword.isEmpty, !confirmPassword.isEmpty else { return }
        guard newPassword == confirmPassword else {
            error = "Passwords do not match."
            return
        }
        isLoading = true
        error = nil
        let url = URL(string: "\(APIConfig.baseURL)/api/user/forgot_password")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "hash": resetToken,
            "new_password": newPassword
        ]
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
                    isSuccess = true
                }
            }
        }.resume()
    }
}
// --- Preview ---

struct NewPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        NewPasswordView(resetToken: "sampletoken123")
    }
}
