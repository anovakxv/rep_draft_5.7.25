//  RepRoleModel.swift
//  Rep
//
//  Created by Dmytro Holovko on 10.12.2023.
//

import Foundation

enum RepTypeModel: String, CaseIterable, Identifiable, Codable {
    case lead = "Lead"
    case team = "Team"

    // MARK: - Identifiable
    var id: String { self.rawValue }

    // MARK: - CustomStringConvertible
    static var title: String { "Rep Type" }
    var description: String {
        switch self {
        case .lead: return "Lead"
        case .team: return "Team"
        }
    }
}

