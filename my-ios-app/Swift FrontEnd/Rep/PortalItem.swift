//
//  PortalItem.swift
//  Rep
//
//  Created by Adam Novak on 06.15.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

import SwiftUI

struct PortalItem: View {
    let portal: Portal

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
                .frame(width: 80, height: 45)
                .clipped()
                .cornerRadius(6)
            } else {
                Color.gray.opacity(0.2)
                    .frame(width: 80, height: 45)
                    .cornerRadius(6)
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
        .padding(.vertical, 8)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 2)
        .frame(height: 64)
    }
}

