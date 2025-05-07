//
//  PortalCategory.swift
//  Rep
//
//  Created by Dmytro Holovko on 29.10.2023.
//

import Foundation

extension PortalModel {
    enum PortalCategory: String, CaseIterable {
        case health = "Health"
        case business = "Business"
        case software = "Software"
        case events = "Events"
    }
}
