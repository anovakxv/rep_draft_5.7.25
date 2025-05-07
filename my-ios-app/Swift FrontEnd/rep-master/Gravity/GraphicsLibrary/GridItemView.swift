//
//  LoginView.swift
//  Rep 
//
//  Created by Dmytro Holovko on 04.12.2023.
//

import SwiftUI

struct GridItemView: View {
    let size: Double
    let item: ImageItem

    var body: some View {
        ZStack(alignment: .topTrailing) {
            AsyncImage(url: item.url) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipped()
            } placeholder: {
                ProgressView()
            }
            .frame(width: size, height: size)
        }
        .accentColor(.green)
    }
}
