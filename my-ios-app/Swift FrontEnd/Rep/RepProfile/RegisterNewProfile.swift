//  RegisterNewProfile.swift
//  Rep
//
//  Created by Adam Novak on 06.23.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

import SwiftUI
import Combine
import FirebaseMessaging

// --- Keyboard Avoidance Helper ---
final class KeyboardResponder: ObservableObject {
    @Published var currentHeight: CGFloat = 0
    private var cancellableSet: Set<AnyCancellable> = []

    init() {
        let willShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .map { ($0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0 }
        let willHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }

        Publishers.Merge(willShow, willHide)
            .receive(on: RunLoop.main)
            .assign(to: \.currentHeight, on: self)
            .store(in: &cancellableSet)
    }
}

// --- Keyboard dismiss helper ---
extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// --- Custom Styled TextField for better placeholder and input readability ---
struct StyledTextField: View {
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

struct RegisterNewProfileView: View {
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var phone: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var navigateToLogin: Bool = false

    // AppStorage for registration state and userId
    @AppStorage("isRegistered") var isRegistered: Bool = false
    @AppStorage("userId") var userId: Int = 0
    @AppStorage("jwtToken") var jwtToken: String = ""
    @AppStorage("pendingUserId") var pendingUserId: Int = 0
    @AppStorage("onboardingComplete") var onboardingComplete: Bool = false
    @AppStorage("pendingFirstName") var pendingFirstName: String = ""
    @AppStorage("pendingLastName") var pendingLastName: String = ""

    // Use a persistent onboarding profile view model
    @StateObject private var onboardingProfileVM = ProfileInfoViewModel(
        profileInfo: ProfileInfo(
            firstName: "",
            lastName: "",
            skills: [],
            type: .lead,
            cityName: "",
            image: nil,
            about: "",
            broadcast: "",
            otherSkill: ""
        ),
        mode: .edit
    )

    @StateObject private var keyboard = KeyboardResponder()

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    // --- Moved Login prompt to the top ---
                    HStack {
                        Text("Already have an account? :")
                            .font(.custom("Inter", size: 16))
                            .foregroundColor(.gray)
                        Button(action: {
                            UIApplication.shared.endEditing() // Dismiss keyboard
                            navigateToLogin = true
                        }) {
                            Text("Login")
                                .font(.custom("Inter", size: 24).weight(.bold))
                                .foregroundColor(Color.repGreen)
                                .frame(height: 60)
                                .padding(.horizontal, 24)
                        }
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 8)

                    Spacer().frame(height: 8)

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
                        Text("Create Account:")
                            .font(.custom("Inter", size: 20).weight(.bold))
                            .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.16))

                        HStack(spacing: 12) {
                            StyledTextField(placeholder: "First Name", text: $firstName, autocapitalization: .words)
                            StyledTextField(placeholder: "Last Name", text: $lastName, autocapitalization: .words)
                        }

                        Text("Email:")
                            .font(.custom("Inter", size: 20).weight(.bold))
                            .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.16))
                            .padding(.top, 8)

                        StyledTextField(placeholder: "Email address", text: $email, keyboardType: .emailAddress, autocapitalization: .never)

                        StyledTextField(placeholder: "Password", text: $password, isSecure: true)
                        StyledTextField(placeholder: "Confirm Password", text: $confirmPassword, isSecure: true)
                        StyledTextField(placeholder: "Phone number (optional)", text: $phone, keyboardType: .phonePad, autocapitalization: .never)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    Spacer()

                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding(.bottom, 8)
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
                                .font(.custom("Inter", size: 18).weight(.bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 64)
                        }
                    }
                    .background(Color(red: 0.48, green: 0.75, blue: 0.29))
                    .cornerRadius(16)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .disabled(isLoading)

                    // Progress bar at bottom
                    Rectangle()
                        .frame(width: 134, height: 5)
                        .foregroundColor(.black)
                        .cornerRadius(100)
                        .padding(.bottom, 16)

                    Spacer().frame(height: 40)
                }
                .padding(.bottom, keyboard.currentHeight)
                .animation(.easeOut(duration: 0.2), value: keyboard.currentHeight)
            }
            NavigationLink(destination: LoginView(), isActive: $navigateToLogin) {
                EmptyView()
            }
        }
        .navigationBarBackButtonHidden(true) // <-- Correct placement
    }

    // --- Registration logic ---
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
        var request = URLRequest(url: URL(string: "\(APIConfig.baseURL)/api/user/register")!)
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
                var newUserId: Int?
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let user = json["user"] as? [String: Any],
                    let id = user["id"] as? Int {
                    newUserId = id
                }
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let token = json["token"] as? String {
                    jwtToken = token
                }

                // Set onboarding flags for root navigation
                if let id = newUserId {
                    pendingUserId = id // Store for onboarding
                }
                pendingFirstName = firstName
                pendingLastName = lastName
                isRegistered = true // <-- This triggers onboarding flow in RootAppView
                onboardingComplete = false

                print("DEBUG: isRegistered=\(isRegistered), pendingUserId=\(pendingUserId), jwtToken=\(jwtToken), onboardingComplete=\(UserDefaults.standard.bool(forKey: "onboardingComplete"))")

                // Update the onboardingProfileVM with the new user's info
                onboardingProfileVM.profileInfo.firstName = firstName
                onboardingProfileVM.profileInfo.lastName = lastName
                onboardingProfileVM.profileInfo.type = .lead
                onboardingProfileVM.profileInfo.cityName = ""
                onboardingProfileVM.profileInfo.image = nil
                onboardingProfileVM.profileInfo.about = ""
                onboardingProfileVM.profileInfo.broadcast = ""
                onboardingProfileVM.profileInfo.otherSkill = ""
                onboardingProfileVM.profileInfo.skills = []

                // --- Register FCM token after registration ---
                Messaging.messaging().token { token, error in
                    guard let token = token, !jwtToken.isEmpty, let id = newUserId, id > 0 else { return }
                    guard let url = URL(string: "\(APIConfig.baseURL)/api/user/device_token") else { return }
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
                    let body: [String: Any] = ["device_token": token]
                    request.httpBody = try? JSONSerialization.data(withJSONObject: body)
                    URLSession.shared.dataTask(with: request) { _, response, _ in
                        if let httpResponse = response as? HTTPURLResponse {
                            print("FCM token sent to backend after registration, status: \(httpResponse.statusCode)")
                        }
                    }.resume()
            }
            // --- End FCM registration ---
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
