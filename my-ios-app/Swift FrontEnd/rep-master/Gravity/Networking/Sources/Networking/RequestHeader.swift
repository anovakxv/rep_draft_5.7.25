//
//  RequestHeader.swift
//  
//
//  Created by Dmytro Holovko on 12.12.2023.
//

import Foundation

public struct RequestHeader {
    let name: Name
    let value: String
}

public extension RequestHeader {
    static func authorization(bearerToken: String) -> RequestHeader {
        RequestHeader(name: .authorization, value: "Bearer \(bearerToken)")
    }

    static func contentType(_ value: ContentType) -> RequestHeader {
        RequestHeader(name: .contentType, value: value.rawValue)
    }
}

public extension RequestHeader {
    enum Name: String {
        case authorization = "Authorization"
        case contentType = "Content-Type"
    }
}

public enum ContentType: String {
    case applicationJson = "application/json"
}
