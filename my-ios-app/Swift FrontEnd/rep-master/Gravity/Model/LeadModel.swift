//
//  LeadModel.swift
//  Rep 
//
//  Created by Dmytro Holovko on 29.10.2023.
//

import Foundation

struct LeadModel: Identifiable {
    let id: String
    let firstName: String
    let lastName: String
    let imageName: String
    let city: String
    let repType: String
    let additionalInfo: String
}

extension LeadModel {
    var shortName: String {
        String(firstName.first?.description ?? "")
        + String(lastName.first?.description ?? "")
    }
}
