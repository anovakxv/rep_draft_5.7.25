//
//  AuthAPIProvidable.swift
//  Rep Social
//
//  Created by Dmytro Holovko on 13.12.2023.
//

import Foundation
import Networking
import Combine

public protocol AuthAPIProvidable {
    func login(with dto: LoginDTO) -> AnyPublisher<AuthResponse, ServiceError>
    func signup(with dto: SignUpDTO) -> AnyPublisher<AuthResponse, ServiceError>
    func changePassword(with dto: ChangePasswordDTO) -> AnyPublisher<ChangePasswordResponse, ServiceError>
    func logout(with token: String) -> AnyPublisher<LogoutResponse, ServiceError>
}
