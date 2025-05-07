//
//  URLRequest+AddValue.swift
//
//
//  Created by Dmytro Holovko on 12.12.2023.
//

import Foundation

extension URLRequest {
    mutating func addValue(_ header: RequestHeader) {
        addValue(header.value, forHTTPHeaderField: header.name.rawValue)
    }
}
