//
//  Toolbar.swift
//  Rep
//
//  Created by Dmytro Holovko on 29.10.2023.
//

import SwiftUI

struct ToolBar: View {
    var action: () -> Void
    
    var body: some View {
        ZStack {
            HStack {
                Spacer()
                Button(action: {
                    // Handle button tap
                }) {
                    Image(systemName: "message")
                        .foregroundColor(.green)
                }
            }
            Button(action: action) {
                Image(systemName: "plus")
                    .foregroundColor(.white)
                    .padding(.horizontal, 100)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
    }
}
