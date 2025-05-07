//
//  LoginDTO.swift
//  Rep Social
//
//  Created by Dmytro Holovko on 13.12.2023.
//

import Foundation

public struct LoginDTO: Codable {
    public let email: String
    public let password: String
    
    public init(
        email: String,
        password: String
    ) {
        self.password = password
        self.email = email
    }
}
