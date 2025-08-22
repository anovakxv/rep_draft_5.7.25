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
        // Compute once outside the ViewBuilder (safe in all SwiftUI versions)
        let tagText: String = {
            if goal.typeName.lowercased() == "other" {
                let raw = goal.metricName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !raw.isEmpty else { return goal.typeName }
                return String(raw.prefix(9))
            } else {
                return goal.typeName
            }
        }()

        return HStack(alignment: .center, spacing: 16) {
            // Bar Chart
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(goal.chartData.suffix(4)) { bar in
                    let quota = goal.quota > 0 ? goal.quota : 1
                    let barHeight = max(0, min(1.0, CGFloat(bar.value / quota)) * 77)
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        Rectangle()
                            .fill(Color.repGreen)
                            .frame(width: 24, height: barHeight)
                            .cornerRadius(3)
                    }
                }
            }
            .frame(width: 4 * 24 + 3 * 6, height: 81, alignment: .leading)
            .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title)
                    .font(.headline)
                if !goal.subtitle.isEmpty {
                    Text(goal.subtitle)
                        .font(.subheadline)
                }

                // Use the computed tagText
                Text("\(Int(goal.progressPercent))% [\(tagText)]")
                    .font(.callout)
                    .foregroundColor(.black)
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