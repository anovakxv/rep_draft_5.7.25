//
//  RegisterNewProfile.swift
//  Rep
//
//  Created by Adam Novak on 06.23.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

import SwiftUI

struct RegisterNewProfileView: View {
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var phone: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var navigateToEditProfile: Bool = false
    @State private var registeredUser: ProfileInfo = ProfileInfo(
        firstName: "",
        lastName: "",
        skills: [],
        type: .lead,
        cityName: "",
        image: nil,
        about: "",
        broadcast: "",
        otherSkill: ""
    )

    // AppStorage for registration state and userId
    @AppStorage("isRegistered") var isRegistered: Bool = false
    @AppStorage("userId") var userId: Int = 0
    @AppStorage("jwtToken") var jwtToken: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Status Bar
                    HStack {
                        Text("9:41")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                        Spacer()
                    }
                    .frame(height: 48)
                    .padding(.horizontal, 19)
                    .background(Color(UIColor(red: 0.976, green: 0.976, blue: 0.976, alpha: 1.0)))

                    Spacer().frame(height: 32)

                    // Rep Logo
                    HStack {
                        Spacer()
                        Image("REPLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                        Spacer()
                    }
                    .padding(.bottom, 24)

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your Info:")
                            .font(.custom("Inter", size: 20).weight(.bold))
                            .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.16))

                        HStack(spacing: 12) {
                            TextField("First Name", text: $firstName)
                                .padding()
                                .background(Color(red: 0.95, green: 0.95, blue: 0.95))
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color(red: 0.48, green: 0.75, blue: 0.29), lineWidth: 1)
                                )
                            TextField("Last Name", text: $lastName)
                                .padding()
                                .background(Color(red: 0.95, green: 0.95, blue: 0.95))
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color(red: 0.48, green: 0.75, blue: 0.29), lineWidth: 1)
                                )
                        }

                        Text("Email:")
                            .font(.custom("Inter", size: 20).weight(.bold))
                            .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.16))
                            .padding(.top, 8)

                        Text("You will receive a confirmation email.")
                            .font(.custom("Inter", size: 15))
                            .foregroundColor(Color(red: 0.47, green: 0.47, blue: 0.47))

                        TextField("Email address", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color(red: 0.95, green: 0.95, blue: 0.95))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(red: 0.48, green: 0.75, blue: 0.29), lineWidth: 1)
                            )

                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color(red: 0.95, green: 0.95, blue: 0.95))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(red: 0.48, green: 0.75, blue: 0.29), lineWidth: 1)
                            )

                        SecureField("Confirm Password", text: $confirmPassword)
                            .padding()
                            .background(Color(red: 0.95, green: 0.95, blue: 0.95))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(red: 0.48, green: 0.75, blue: 0.29), lineWidth: 1)
                            )

                        TextField("Phone number (optional)", text: $phone)
                            .keyboardType(.phonePad)
                            .padding()
                            .background(Color(red: 0.95, green: 0.95, blue: 0.95))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(red: 0.48, green: 0.75, blue: 0.29), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    Spacer()

                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding(.bottom, 8)
                    }

                    NavigationLink(
                        destination: EditProfileView(
                            viewModel: ProfileInfoViewModel(
                                profileInfo: registeredUser,
                                mode: .edit
                            )
                        ),
                        isActive: $navigateToEditProfile
                    ) {
                        EmptyView()
                    }

                    Button(action: {
                        registerUser()
                    }) {
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                        } else {
                            Text("Next")
                                .font(.custom("Inter", size: 16).weight(.semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                        }
                    }
                    .background(Color(red: 0.48, green: 0.75, blue: 0.29))
                    .cornerRadius(14)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .disabled(isLoading)

                    // Progress bar at bottom
                    Rectangle()
                        .frame(width: 134, height: 5)
                        .foregroundColor(.black)
                        .cornerRadius(100)
                        .padding(.bottom, 16)
                }
            }
        }
    }

    func registerUser() {
        errorMessage = nil

        // Basic validation
        guard !firstName.isEmpty, !lastName.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all required fields."
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }

        isLoading = true

        // Prepare multipart/form-data body
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: "http://localhost:5000/api/user/register")!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        func appendFormField(_ name: String, _ value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        appendFormField("fname", firstName)
        appendFormField("lname", lastName)
        appendFormField("email", email)
        appendFormField("password", password)
        if !phone.isEmpty {
            appendFormField("phone", phone)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }
                guard let data = data else {
                    errorMessage = "No response from server."
                    return
                }
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    if let apiError = try? JSONDecoder().decode([String: String].self, from: data),
                       let msg = apiError["error"] {
                        errorMessage = msg
                    } else {
                        errorMessage = "Registration failed. Please try again."
                    }
                    return
                }
                // Registration successful
                // Parse userId and token from response
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let user = json["user"] as? [String: Any],
                   let newUserId = user["id"] as? Int {
                    userId = newUserId
                }
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let token = json["token"] as? String {
                    jwtToken = token
                }
                isRegistered = true

                registeredUser = ProfileInfo(
                    firstName: firstName,
                    lastName: lastName,
                    skills: [],
                    type: .lead,
                    cityName: "",
                    image: nil,
                    about: "",
                    broadcast: "",
                    otherSkill: ""
                )
                navigateToEditProfile = true
            }
        }.resume()
    }
}

// MARK: - Preview

struct RegisterNewProfileView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterNewProfileView()
    }
}

