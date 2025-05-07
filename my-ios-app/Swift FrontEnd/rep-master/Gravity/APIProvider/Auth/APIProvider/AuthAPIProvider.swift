//
//  AuthAPIProvider.swift
//  Rep Social
//
//  Created by Dmytro Holovko on 12.12.2023.
//

import Foundation
import Networking
import Combine

public final class AuthAPIProvider: AuthAPIProvidable {
    private let networkService: any NetworkServicing
    
    public init(networkService: any NetworkServicing) {
        self.networkService = networkService
    }
    
    public func login(with dto: LoginDTO) -> AnyPublisher<AuthResponse, Networking.ServiceError> {
        networkService.execute(AuthRequest.login(dto))
    }
    
    public func signup(with dto: SignUpDTO) -> AnyPublisher<AuthResponse, Networking.ServiceError> {
        networkService.execute(AuthRequest.signup(dto))
    }
    
    public func changePassword(with dto: ChangePasswordDTO) -> AnyPublisher<ChangePasswordResponse, Networking.ServiceError> {
        networkService.execute(AuthRequest.changePassword(dto))
    }
    
    public func logout(with token: String) -> AnyPublisher<LogoutResponse, Networking.ServiceError> {
        networkService.execute(AuthRequest.logout(token))
    }
}
