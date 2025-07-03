//
//  RepRoleModel.swift
//  Rep 
//
//  Created by Dmytro Holovko on 10.12.2023.
//

import Foundation

enum RepTypeModel: String {
    case lead = "Lead"
    case team = "Team"
}

// MARK: - RepRoleModel + CustomStringConvertible -

extension RepTypeModel: CustomStringConvertible {
    static var title: String {
        "Rep Type"
    }
    
    var description: String {
        switch self {
        case .lead: return "Lead"
        case .team: return "Team"
        }
    }
}

// MARK: - RepRoleModel + Identifiable -

extension RepTypeModel: Identifiable {
    var id: String {
        self.rawValue
    }
}

// MARK: - RepRoleModel + CaseIterable -

extension RepTypeModel: CaseIterable {}


