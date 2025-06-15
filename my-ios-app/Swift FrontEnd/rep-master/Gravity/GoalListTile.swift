//
//  GoalListItem.swift
//  Rep 
//
//  Created by Dmytro Holovko on 29.10.2023.
//

import SwiftUI

struct BarChartView: View {
    let data: [BarChartData]

struct GoalListItem: View {
    let goal: GoalModel
    let chartData: [BarChartData] // Pass in the data for this goal

    var body: some View {
        HStack(spacing: 12) {
            // Small bar chart on the left, mirrors GoalDetailPage chart
            BarChartView(data: chartData)
                .frame(width: 100, height: 50)
                .padding(.vertical, 7)
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
        .frame(height: 64)
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
