//
//  GoalListItem.swift
//  Rep 
//
//  Created by Dmytro Holovko on 10.29.2023.
//  Edited by Adam Novak on 06.17.2025
//  Updated for API sync on 06.20.2025
//  (c) 2025 Networked Capital Inc. All rights reserved.

import SwiftUI

// MARK: - Bar Chart Data Model

struct BarChartData: Identifiable, Codable {
    let id = UUID()
    let value: Double
    let valueLabel: String
    let bottomLabel: String

    // For preview/demo
    init(value: Double, valueLabel: String, bottomLabel: String) {
        self.value = value
        self.valueLabel = valueLabel
        self.bottomLabel = bottomLabel
    }
}

// MARK: - Bar Chart View

struct BarChartView: View {
    let data: [BarChartData]

    var maxValue: Double {
        data.map { $0.value }.max() ?? 1
    }

    var body: some View {
        VStack(spacing: 2) {
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(data) { bar in
                    Rectangle()
                        .fill(Color.repGreen)
                        .frame(width: 14, height: CGFloat(bar.value / maxValue) * 40)
                        .cornerRadius(3)
                }
            }
            HStack(spacing: 6) {
                ForEach(data) { bar in
                    Text(bar.bottomLabel)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 14)
                }
            }
        }
        .frame(width: 70, height: 56)
    }
}

// MARK: - Goal Model (Synced with API)

struct GoalModel: Identifiable, Codable {
    let id: Int
    let title: String
    let subtitle: String
    let progressPercent: Double
    let typeName: String
    let chartData: [BarChartData]

    // For preview/demo
    init(id: Int = 1, title: String, subtitle: String, progressPercent: Double, typeName: String, chartData: [BarChartData]) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.progressPercent = progressPercent
        self.typeName = typeName
        self.chartData = chartData
    }
}

// MARK: - Goal List Item

struct GoalListItem: View {
    let goal: GoalModel

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
    static let sampleGoal = GoalModel(
        title: "Grow Membership",
        subtitle: "Increase by 20% this year",
        progressPercent: 60,
        typeName: "Recruiting",
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

// MARK: - Color Extension

extension Color {
    static let repGreen = Color(red: 0/255, green: 200/255, blue: 83/255)
}
