//  Edit_Goal.swift
//  Rep
//
//  Created by Adam Novak: July 2025
//  (c) 2025 Networked Capital Inc. All rights reserved.

import SwiftUI

// MARK: - ReportingIncrement Model

struct ReportingIncrement: Identifiable, Codable, Hashable {
    let id: Int
    let title: String
}

// MARK: - API Response Model

struct ReportingIncrementsResponse: Codable {
    let reportingIncrements: [ReportingIncrement]
}

// MARK: - Edit/Add Goal Page

struct EditGoalPage: View {
    // If editing, pass an existing goal; if adding, pass nil
    var existingGoal: Goal?
    var portalId: Int? // Pass nil for user-only goals
    var userId: Int
    var reportingIncrements: [ReportingIncrement]
    var associatedPortalName: String? // Pass portal name if present, else nil

    @State private var title: String = ""
    @State private var subtitle: String = ""
    @State private var description: String = ""
    @State private var quota: String = ""
    @State private var goalType: String = "Recruiting"
    @State private var metric: String = ""
    @State private var reportingIncrementId: Int?
    @State private var isSaving = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    // For dynamic increments
    @State private var loadedIncrements: [ReportingIncrement] = []
    @State private var isLoadingIncrements = false

    let goalTypes = ["Recruiting", "Sales", "Fund", "Marketing", "Hours", "Other"]

    var isEdit: Bool { existingGoal != nil }

    var incrementsToUse: [ReportingIncrement] {
        !loadedIncrements.isEmpty ? loadedIncrements : reportingIncrements
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(isEdit ? "Edit Goal" : "Add Goal")) {
                    TextField("Title", text: $title)
                    TextField("Subtitle", text: $subtitle)
                    TextField("Description", text: $description)
                    Picker("Goal Type", selection: $goalType) {
                        ForEach(goalTypes, id: \.self) { type in
                            Text(type)
                        }
                    }
                    if goalType == "Other" {
                        TextField("Metric", text: $metric)
                    }
                    TextField("Quota", text: $quota)
                        .keyboardType(.numberPad)
                    if !incrementsToUse.isEmpty && reportingIncrementId != nil {
                        Picker("Reporting Increment", selection: $reportingIncrementId) {
                            ForEach(incrementsToUse, id: \.id) { increment in
                                Text(increment.title).tag(Optional(increment.id))
                            }
                        }
                        .id(reportingIncrementId) // Force Picker to update when selection changes
                    } else {
                        ProgressView("Loading increments...")
                    }
                }
                Section(header: Text("Associated Portal")) {
                    Text(associatedPortalName ?? "N/A")
                        .foregroundColor(.secondary)
                }
                Section {
                    Button(isEdit ? "Save Changes" : "Add Goal") {
                        saveGoal()
                    }
                    .disabled(isSaving || title.isEmpty || quota.isEmpty || reportingIncrementId == nil)
                }
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle(isEdit ? "Edit Goal" : "Add Goal")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                loadReportingIncrements()
                if let goal = existingGoal {
                    title = goal.title
                    subtitle = goal.subtitle
                    description = goal.description
                    quota = "\(Int(goal.quota))"
                    goalType = goal.typeName
                    metric = goal.metricName
                    // Try to match reporting increment by name
                    let increments = incrementsToUse
                    if let match = increments.first(where: { $0.title == goal.reportingName }) {
                        reportingIncrementId = match.id
                    }
                }
                // For new goals, do NOT set reportingIncrementId here.
                // Let loadReportingIncrements() handle the default after increments are loaded.
            }
        }
    }

    private func loadReportingIncrements() {
        guard !isLoadingIncrements else { return }
        isLoadingIncrements = true
        guard let url = URL(string: "\(APIConfig.baseURL)/api/goals/reporting_increments"),
              let token = UserDefaults.standard.string(forKey: "jwtToken") else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, _, _ in
            defer { isLoadingIncrements = false }
            guard let data = data else { return }
            if let decoded = try? JSONDecoder().decode(ReportingIncrementsResponse.self, from: data) {
                DispatchQueue.main.async {
                    self.loadedIncrements = decoded.reportingIncrements
                    // Set default selection if not set
                    if self.reportingIncrementId == nil {
                        print("EditGoal: Titles in increments: \(decoded.reportingIncrements.map { $0.title })")
                        if let goal = existingGoal,
                            let match = decoded.reportingIncrements.first(where: { $0.title == goal.reportingName }) {
                            self.reportingIncrementId = match.id
                            print("EditGoal: Matched existing goal increment: \(match.title) (\(match.id))")
                        } else if let daily = decoded.reportingIncrements.first(where: { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "daily" }) {
                            self.reportingIncrementId = daily.id
                            print("EditGoal: Defaulting to Daily increment: \(daily.title) (\(daily.id))")
                        } else if let first = decoded.reportingIncrements.first {
                            self.reportingIncrementId = first.id
                            print("EditGoal: Defaulting to first increment: \(first.title) (\(first.id))")
                        }
                        print("EditGoal: All increments loaded: \(decoded.reportingIncrements.map { "\($0.title) (\($0.id))" })")
                        print("EditGoal: reportingIncrementId set to: \(String(describing: self.reportingIncrementId))")
                    }
                }
            }
        }.resume()
    }

    func saveGoal() {
        isSaving = true
        errorMessage = nil
        let urlString: String
        var params: [String: Any] = [
            "title": title,
            "subtitle": subtitle,
            "description": description,
            "goal_type": goalType,
            "quota": Int(quota) ?? 1,
            "reporting_increments_id": reportingIncrementId ?? 1,
            "user_id": userId
        ]
        if let portalId = portalId, portalId != 0 {
            params["portals_id"] = portalId
        }
        if goalType == "Other" {
            params["metric"] = metric
        }
        if isEdit, let goal = existingGoal {
            urlString = "\(APIConfig.baseURL)/api/goals/edit"
            params["goals_id"] = goal.id
        } else {
            urlString = "\(APIConfig.baseURL)/api/goals/create"
        }

        guard let url = URL(string: urlString),
              let body = try? JSONSerialization.data(withJSONObject: params) else {
            isSaving = false
            errorMessage = "Invalid request."
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "jwtToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isSaving = false
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }
                guard let data = data else {
                    errorMessage = "No response from server."
                    return
                }
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let err = json["error"] as? String {
                        errorMessage = err
                    } else {
                        errorMessage = "Server error."
                    }
                    return
                }
                dismiss()
            }
        }.resume()
    }
}