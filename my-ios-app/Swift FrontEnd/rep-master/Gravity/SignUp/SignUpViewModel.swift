//
//  SignUpViewModel.swift
//  Rep 
//
//  Created by Dmytro Holovko on 13.12.2023.
//

import Foundation
import Combine
import Networking
import Dependiject

protocol SignUpViewModel: AnyObservableObject {
    var model: SignUpModel { get set }
    var isLoading: Bool { get }
    var error: ServiceError? { get set }
    var isLoggedIn: Bool { get set }
    
    func signup()
}

public final class SimpleSignUpViewModel: SignUpViewModel, ObservableObject {
    @Published var model = SignUpModel()
    @Published var isLoading = false
    @Published var error: ServiceError? = nil
    @Published var isLoggedIn = false
    
    @KeychainWrapper(authTokenKey, defaultValue: nil)
    private var authToken: String?
    private var networkService: any NetworkServicing
    private let authAPIProvider: AuthAPIProvidable
    private var cancellables = Set<AnyCancellable>()
    
    init(
        authAPIProvider: AuthAPIProvidable,
        networkService: any NetworkServicing
    ) {
        self.authAPIProvider = authAPIProvider
        self.networkService = networkService
    }
    
    func signup() {
        guard model.isValid else {
            error = ServiceError.inputDataError
            return
        }
        isLoading = true
        authAPIProvider
            .signup(with: .init(from: model))
            .handleEvents(receiveOutput: { [weak self] response in
                self?.authToken = response.token
                self?.networkService.token = response.token
            })
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case let .failure(cError) = completion {
                        self?.error = cError
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.isLoggedIn = true
                }
            )
            .store(in: &cancellables)
    }
}
