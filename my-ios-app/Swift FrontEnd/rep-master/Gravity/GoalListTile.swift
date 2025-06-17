//
//  GoalListItem.swift
//  Rep 
//
//  Created by Dmytro Holovko on 29.10.2023.
//  Edited by Adam Novak on 06.17.2025
//  (c) 2025 Networked Capital Inc. All rights reserved.
import SwiftUI

// MARK: - Bar Chart Data Model

struct BarChartData: Identifiable {
    let id = UUID()
    let value: Double
    let label: String
    let color: Color
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
                        .fill(bar.color)
                        .frame(width: 14, height: CGFloat(bar.value / maxValue) * 40)
                        .cornerRadius(3)
                }
            }
            HStack(spacing: 6) {
                ForEach(data) { bar in
                    Text(bar.label)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 14)
                }
            }
        }
        .frame(width: 70, height: 56)
    }
}

// MARK: - Goal Model

struct GoalModel: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let progress: Int
    let chartData: [BarChartData]
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
                Text(goal.subtitle)
                    .font(.subheadline)
                Text("\(goal.progress)% [Recruiting]")
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
        progress: 60,
        chartData: [
            BarChartData(value: 10, label: "Jan", color: .green),
            BarChartData(value: 30, label: "Feb", color: .green),
            BarChartData(value: 20, label: "Mar", color: .green),
            BarChartData(value: 40, label: "Apr", color: .green)
        ]
    )

    static var previews: some View {
        GoalListItem(goal: sampleGoal)
            .previewLayout(.sizeThatFits)
            .background(Color(UIColor.systemGroupedBackground))
            
