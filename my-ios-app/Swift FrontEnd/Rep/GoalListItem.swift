//  GoalListItem.swift
//  Rep
//
//  Created by Dmytro Holovko on 10.29.2023.
//  Edited by Adam Novak on 06.17.2025
//  (c) 2025 Networked Capital Inc. All rights reserved.

import SwiftUI

// MARK: - Goal List Item

struct GoalListItem: View {
    let goal: Goal

    var body: some View {
        HStack(spacing: 16) {
            BarChartView(data: goal.chartData)
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title)
                    .font(.headline)
                if !goal.subtitle.isEmpty {
                    Text(goal.subtitle)
                        .font(.subheadline)
                }
                Text("\(Int(goal.progressPercent))% [\(goal.typeName)]")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .frame(height: 64)
        .padding(.vertical, 4)
        .padding(.horizontal)
        .background(Color.white)
    }
}

// MARK: - Preview

struct GoalListItem_Previews: PreviewProvider {
    static let sampleGoal = Goal(
        id: 1,
        title: "Grow Membership",
        subtitle: "Increase by 20% this year",
        description: "",
        progress: 0.6,
        progressPercent: 60,
        quota: 100,
        filledQuota: 60,
        metricName: "Members",
        typeName: "Recruiting",
        reportingName: "Monthly",
        quotaString: "100",
        valueString: "60",
        chartData: [
            BarChartData(value: 10, valueLabel: "10", bottomLabel: "Jan"),
            BarChartData(value: 30, valueLabel: "30", bottomLabel: "Feb"),
            BarChartData(value: 20, valueLabel: "20", bottomLabel: "Mar"),
            BarChartData(value: 40, valueLabel: "40", bottomLabel: "Apr")
        ]
    )

    static var previews: some View {
        GoalListItem(goal: sampleGoal)
            .previewLayout(.sizeThatFits)
            .background(Color(UIColor.systemGroupedBackground))
    }
}