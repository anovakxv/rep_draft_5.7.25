//  PortalItem.swift
//  Rep
//
//  Created by Adam Novak on 06.15.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

import SwiftUI
import Kingfisher

struct PortalItem: View {
    let portal: Portal

    // 16:9 ratio for width 144: height = 144 * 9 / 16 = 81
    private let imageWidth: CGFloat = 144
    private let imageHeight: CGFloat = 81

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            if let urlString = portal.mainImageUrl, let url = URL(string: urlString) {
                KFImage(url)
                    .resizable()
                    .aspectRatio(16/9, contentMode: .fill)
                    .frame(width: imageWidth, height: imageHeight)
                    .clipped()
                    .cornerRadius(3)
            } else {
                Color.gray.opacity(0.2)
                    .frame(width: imageWidth, height: imageHeight)
                    .cornerRadius(3)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(portal.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .fixedSize(horizontal: false, vertical: true)
                if let category = portal.categories_id {
                    Text("Category \(category)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                if let subtitle = portal.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 17))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack {
                    if let city = portal.cities_id {
                        Text("City \(city)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if let count = portal._c_users_count {
                        Text("\(count) leads")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                    }
                }
            }
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