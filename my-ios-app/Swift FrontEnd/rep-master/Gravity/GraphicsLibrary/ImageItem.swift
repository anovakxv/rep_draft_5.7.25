//
//  LoginView.swift
//  Rep 
//
//  Created by Dmytro Holovko on 04.12.2023.
//

import SwiftUI

struct ImageItem: Identifiable {
    let id = UUID()
    let url: URL

}

extension ImageItem: Hashable {}

extension ImageItem: Equatable {
    static func ==(lhs: ImageItem, rhs: ImageItem) -> Bool {
        return lhs.id == rhs.id && lhs.id == rhs.id
    }
}
