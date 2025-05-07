//
//  AuthRequest.swift
//  Rep Social
//
//  Created by Dmytro Holovko on 12.12.2023.
//

import Foundation
import Networking


public extension Encodable {
    var  dictionary: [String: Any] {
        guard let data = try? JSONEncoder.default.encode(self),
                let dictionary = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        else { return [:]}
    return dictionary
  }
}

public enum AuthRequest {
    case login(LoginDTO)
    case signup(SignUpDTO)
    case changePassword(ChangePasswordDTO)
    case logout(String)
}

extension AuthRequest: Request {
    public var isAuthRequired: Bool {
        false
    }
    
    public var headers: [Networking.RequestHeader] {
        [
            .contentType(.applicationJson)
        ]
    }
    
    public var queryParameters: [String : Any] {
        switch self {
        case let .login(dto): 
            return dto.dictionary
        case let .signup(dto): 
            return dto.dictionary
        case let .changePassword(dto): 
            return dto.dictionary
        case let .logout(token): 
            return ["token": token]
        }
    }
    
    public var route: String {
        switch self {
        case .login: return "login"
        case .signup: return "registration"
        case .changePassword: return "change-password"
        case .logout: return "logout"
        }
    }
    
    public var method: Networking.RequestMethod {
        .post
    }
}
