//
//  File.swift
//  Rep 
//
//  Created by Dmytro Holovko on 29.10.2023.
//

import SwiftUI

struct LeadInfoHeader: View {
    var lead: LeadModel
    
    var body: some View {
        HStack(alignment: .top) {
            Image(lead.imageName)
                .resizable()
                .scaledToFill()
                .frame(
                    width: Constants.imageSize,
                    height: Constants.imageSize
                )
                .cornerRadius(Constants.imageSize / 2)
            VStack(alignment: .leading) {
                HStack {
                    Text(Texts.repType + lead.repType)
                    Text(Texts.city + lead.city)
                }
                .font(.headline)
                Text(lead.additionalInfo)
                    .font(.callout)
            }
            Spacer()
        }
    }
}

private extension LeadInfoHeader {
    enum Texts {
        static let repType = "Rep Type: "
        static let city = "City: "
    }
    
    enum Constants {
        static let imageSize: CGFloat = 100
    }
}

#Preview {
    LeadInfoHeader(lead: .init(id: "1", firstName: "Mukundh", lastName: "Pandian", imageName: "leadPic", city: "LA", repType: "Lead", additionalInfo: "1. Human Resources - Scale\n2. Operations - Manufacturing\n3. Sales - Social Connector"))
}
