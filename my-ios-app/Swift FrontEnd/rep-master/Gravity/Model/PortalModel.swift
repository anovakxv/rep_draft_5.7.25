//
//  PortalModel.swift
//  Rep 
//
//  Created by Dmytro Holovko on 29.10.2023.
//

import Foundation

struct PortalModel: Identifiable {
    let id: String
    var title: String
    var subtitle: String
    var city: String
    var imageItems: [ImageItem]
    var description: String
    var categories: [PortalCategory]
    var leads: [LeadModel]
}

extension PortalModel {
    var categoriesText: String {
        categories.map{ $0.rawValue }.joined(separator: ", ")
    }
}
