//
//  LoginViewModel.swift
//  Rep 
//
//  Created by Dmytro Holovko on 13.12.2023
//  Updated by Adam Novak on 06.19.2025
//  (c) 2025 Networked Capital Inc. All rights reserved.

import Foundation
import Combine
import SwiftUI

protocol LoginViewModel: AnyObservableObject {
    var email: String { get set }
    var password: String { get set }
    var isLoggedIn: Bool { get set }
    var isSignUpPresented: Bool { get set }
    var isLoading: Bool { get }
    var error: ServiceError? { get set }
    func login()
    func forgotPassword()
}

class SimpleLoginViewModel: LoginViewModel, ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoggedIn = false
    @Published var isSignUpPresented = false
    @Published var isLoading = false
    @Published var error: ServiceError? = nil
    @Published var forgotPasswordSuccess: Bool = false

    @AppStorage("userId") var userId: Int = 0
    @AppStorage("authToken") var authToken: String = ""

    private var cancellables = Set<AnyCancellable>()

    func login() {
        guard !email.isEmpty && !password.isEmpty else {
            error = ServiceError.inputDataError
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
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> LoginAPIResponse in
                if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                    throw ServiceError.serverError(apiError.error)
                }
                return try JSONDecoder().decode(LoginAPIResponse.self, from: data)
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case let .failure(cError) = completion {
                        if let serviceError = cError as? ServiceError {
                            self?.error = serviceError
                        } else {
                            self?.error = .unknown
                        }
                    }
                },
                receiveValue: { [weak self] apiResult in
                    self?.userId = apiResult.result.id
                    self?.authToken = apiResult.token
                    self?.isLoggedIn = true
                }
            )
            .store(in: &cancellables)
    }

    func forgotPassword() {
        guard !email.isEmpty else {
            error = ServiceError.inputDataError
            return
        }
        // Implement your forgot password API call here
        // For now, just simulate success
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.forgotPasswordSuccess = true
        }
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
            return "An unknown error