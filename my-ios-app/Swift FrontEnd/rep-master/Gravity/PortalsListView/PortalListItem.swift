//
//  PortalListItem.swift
//  Rep 
//
//  Created by Dmytro Holovko on 29.10.2023.
//

import SwiftUI

struct PortalListItem: View {
    var portal: PortalModel
    
    var body: some View {
        HStack {
//            Image(portal.imageName)
//                .resizable()
//                .frame(width: 150)
            HStack {
                VStack(alignment: .leading) {
                    Text(portal.title)
                        .font(.headline)
                    Spacer()
                    Text(portal.subtitle)
                        .font(.subheadline)
                    Spacer()
                    HStack {
                        Text(portal.categoriesText)
                        Spacer()
                        Text(portal.city.uppercased())
                    }
                    .font(.caption2)
                }
            }
        }
        .frame(height: 90)
        .padding()
    }
}

//#Preview {
//    PortalListItem(portal: .init(id: "1", title: "Networked Capital", subtitle: "Rep Something", city: "BOI", imageName: "nwCapitalCover", description: "", categories: [.business, .health], leads: []))
//}
