//
//  AuthResponse.swift
//  Rep Social
//
//  Created by Dmytro Holovko on 13.12.2023.
//

import Foundation

public struct AuthResponse: Decodable {
    public let token: String
    
    public init(token: String) {
        self.token = token
    }
}
