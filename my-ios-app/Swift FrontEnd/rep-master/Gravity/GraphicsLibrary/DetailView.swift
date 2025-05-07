//
//  LoginView.swift
//  Rep 
//
//  Created by Dmytro Holovko on 04.12.2023.
//

import SwiftUI

struct ImageView: View {
    let item: ImageItem

    var body: some View {
        AsyncImage(url: item.url) { image in
            image
                .resizable()
                .scaledToFit()
        } placeholder: {
            ProgressView()
        }
    }
}

struct ImageView_Previews: PreviewProvider {
    static var previews: some View {
        if let url = Bundle.main.url(forResource: "events", withExtension: "png") {
            ImageView(item: ImageItem(url: url))
        }
    }
}
