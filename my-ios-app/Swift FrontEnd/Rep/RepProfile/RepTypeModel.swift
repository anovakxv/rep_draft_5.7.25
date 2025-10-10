//  RepTypeModel.swift
//  Rep
//
//  Created by Dmytro Holovko on 10.12.2023.
//

import Foundation

enum RepTypeModel: String, CaseIterable, Identifiable, Codable {
    case lead = "Lead"
    case team = "Team"
    case admin = "Admin" // <-- Added Admin type

    // MARK: - Identifiable
    var id: String { self.rawValue }

    // MARK: - CustomStringConvertible
    static var title: String { "Rep Type" }
    var description: String {
        switch self {
        case .lead: return "Lead"
        case .team: return "Team"
        case .admin: return "Admin"
        }
    }

    var dbID: Int {
        switch self {
        case .lead: return 1 // Use the actual ID from your user_types table
        case .team: return 2 // Use the actual ID from your user_types table
        case .admin: return 3 // Use the actual ID from your user_types table
        }
    }
}