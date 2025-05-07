//
//  ChangePasswordDTO.swift
//  Rep Social
//
//  Created by Dmytro Holovko on 13.12.2023.
//

import Foundation

public struct ChangePasswordDTO: Codable {
    public let email: String
    public let password: String
    public let newPassword: String
    public let confirmPassword: String
    
    public init(
        email: String,
        password: String,
        newPassword: String,
        confirmPassword: String
    ) {
        self.email = email
        self.password = password
        self.newPassword = newPassword
        self.confirmPassword = confirmPassword
    }
}
