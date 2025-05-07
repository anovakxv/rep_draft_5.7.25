//
//  UserRequest.swift
//  Rep
//
//  Created by Dmytro Holovko on 12.12.2023..
//

import Foundation
import Networking

enum UserRequest {
    case userInfo
    case updateIndo
    case uploadProfilePicture
    case deleteProfilePicture
    case userSkills
    case createUserSkills
}

extension UserRequest: Request {
    var isAuthRequired: Bool {
        true
    }
    
    var headers: [Networking.RequestHeader] {
        [
            .contentType(.applicationJson)
        ]
    }
    
    var queryParameters: [String : Any] {
        [:]
    }
    
    var route: String {
        switch self {
        case .userInfo: 
            return "user​/get-info"
        case .updateIndo: 
            return "user/update"
        case .uploadProfilePicture:
            return "user​/upload-avatar"
        case .deleteProfilePicture:
            return "user​/delete-avatar"
        case .userSkills: 
            return "user-rep-skill​/list"
        case .createUserSkills:
            return "user-rep-skill​/create"
        }
    }
    
    var method: Networking.RequestMethod {
        switch self {
        case .userInfo:
            return .get
        case .updateIndo:
            return .put
        case .uploadProfilePicture:
            return .post
        case .deleteProfilePicture:
            return .delete
        case .userSkills:
            return .get
        case .createUserSkills:
            return .post
        }
    }
}
