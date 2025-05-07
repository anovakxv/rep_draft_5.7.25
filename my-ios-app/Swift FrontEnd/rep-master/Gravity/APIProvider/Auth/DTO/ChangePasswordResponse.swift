//
//  ChangePasswordResponse.swift
//  Rep Social
//
//  Created by Dmytro Holovko on 13.12.2023.
//

import Foundation

public struct ChangePasswordResponse: Decodable {
    public let status: Bool
    
    public init(status: Bool) {
        self.status = status
    }
}
