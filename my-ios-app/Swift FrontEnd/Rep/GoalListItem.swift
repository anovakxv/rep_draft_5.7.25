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
        HStack(alignment: .center, spacing: 16) {
            VStack(spacing: 2) {
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(goal.chartData) { bar in
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            Rectangle()
                                .fill(Color.repGreen)
                                .frame(
                                    width: 24,
                                    height: {
                                        let quota = goal.quota > 0 ? goal.quota : 1
                                        return max(0, CGFloat(bar.value / quota) * 56)
                                    }()
                                )
                                .cornerRadius(3)
                            Text(bar.valueLabel)
                                .font(.caption2)
                                .foregroundColor(.black)
                        }
                        .frame(height: 56 + 16) // 56 for bar, 16 for label
                    }
                    Spacer()
                }
            }
            .frame(width: 144, height: 81)
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
        .frame(height: 81)
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
            BarChartData(id: 1, value: 10, valueLabel: "10", bottomLabel: "Jan"),
            BarChartData(id: 2, value: 30, valueLabel: "30", bottomLabel: "Feb"),
            BarChartData(id: 3, value: 20, valueLabel: "20", bottomLabel: "Mar"),
            BarChartData(id: 4, value: 40, valueLabel: "40", bottomLabel: "Apr")
        ],
        creatorId: 1,
        portalId: 1
    )

    static var previews: some View {
        GoalListItem(goal: sampleGoal)
            .previewLayout(.sizeThatFits)
            .background(Color(UIColor.systemGroupedBackground))
    }
}