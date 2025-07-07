//  SkillModel.swift
//  Rep
//
//  Created by Adam Novak 7.6.25
//

// Once we fully switch to dynamic skills, we can remove RepSkillsModel.swift if it's no longer used.

import Foundation

struct SkillModel: Identifiable, Codable, Hashable, CustomStringConvertible {
    let id: Int
    let title: String
    var description: String { title }
}
