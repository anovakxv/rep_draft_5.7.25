//
//  LogoutResponse.swift
//  Rep Social
//
//  Created by Dmytro Holovko on 13.12.2023.
//

import Foundation

public struct LogoutResponse: Decodable {
    public let message: String
    
    public init(message: String) {
        self.message = message
    }
}
