//
//  GoalListItem.swift
//  Rep 
//
//  Created by Dmytro Holovko on 29.10.2023.
//

import SwiftUI

struct GoalListItem: View {
    var goal: GoalModel
     
    var body: some View {
        HStack {
            Image(systemName: "cellularbars")
                .resizable()
                .frame(width: 100)
                .foregroundColor(.green)
            HStack {
                VStack(alignment: .leading) {
                    Text(goal.title)
                        .font(.headline)
                    Text(goal.subtitle)
                        .font(.subheadline)
                    Spacer()
                    Text("\(goal.progress)% [Recruiting]")
                    .font(.caption2)
                }
            }
            Spacer()
        }
        .frame(height: 90)
        .padding()
    }
}

struct GoalModel: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let progress: Int
}

#Preview {
    GoalListItem(goal: .init(title: "Aboba", subtitle: "adf", progress: 33))
}
