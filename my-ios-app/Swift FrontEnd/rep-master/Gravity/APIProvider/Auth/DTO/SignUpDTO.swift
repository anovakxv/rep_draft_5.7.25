//
//  SignupDTO.swift
//  Rep Social
//
//  Created by Dmytro Holovko on 13.12.2023.
//

import Foundation

public struct SignUpDTO: Codable {
    public let email: String
    public let password: String
    public let confirmPassword: String
    public let name: String
    public let surname: String
    public let phone: String
    
    init(
        email: String,
        password: String,
        confirmPassword: String,
        name: String,
        surname: String,
        phone: String
    ) {
        self.email = email
        self.password = password
        self.confirmPassword = confirmPassword
        self.name = name
        self.surname = surname
        self.phone = phone
    }
}
