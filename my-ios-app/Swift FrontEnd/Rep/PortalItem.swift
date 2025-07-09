//  PortalItem.swift
//  Rep
//
//  Created by Adam Novak on 06.15.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

import SwiftUI

struct PortalItem: View {
    let portal: Portal

    // 16:9 ratio for width 144: height = 144 * 9 / 16 = 81
    private let imageWidth: CGFloat = 144
    private let imageHeight: CGFloat = 81

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            if let urlString = portal.mainImageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                    } else if phase.error != nil {
                        Color.gray
                    } else {
                        Color.gray.opacity(0.3)
                    }
                }
                .frame(width: imageWidth, height: imageHeight)
                .clipped()
                .cornerRadius(3)
            } else {
                Color.gray.opacity(0.2)
                    .frame(width: imageWidth, height: imageHeight)
                    .cornerRadius(3)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(portal.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Spacer()
                    // Add category if available
                    if let category = portal.categories_id {
                        Text("Category \(category)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let subtitle = portal.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                HStack {
                    if let city = portal.cities_id {
                        Text("City \(city)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if let count = portal._c_users_count {
                        Text("\(count) leads")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0))),
            alignment: .bottom
        )
        .frame(height: imageHeight + 24)
    }
}