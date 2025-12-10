//
//  ReactionPicker.swift
//  Rep
//
//  Created by Adam Novak on 12.09.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

import SwiftUI

struct ReactionPicker: View {
    @Environment(\.dismiss) private var dismiss

    let onSelectEmoji: (String) -> Void

    // Popular emojis matching web app
    let popularEmojis = ["👍", "❤️", "😂", "😮", "👎", "🙏", "🎉"]

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Add Reaction")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)

            // Emoji grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ForEach(popularEmojis, id: \.self) { emoji in
                    Button(action: {
                        onSelectEmoji(emoji)
                        dismiss()
                    }) {
                        Text(emoji)
                            .font(.system(size: 40))
                            .frame(width: 60, height: 60)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal, 32)
    }
}
