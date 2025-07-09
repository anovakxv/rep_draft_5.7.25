//
//  UpdateGoalSheet.swift
//  Rep
//
//  Created by Adam Novak on 07.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

import SwiftUI

struct UpdateGoalSheet: View {
    let goalId: Int
    let quota: Double
    let metricName: String

    @State private var addedValue: String = ""
    @State private var note: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Update Progress")) {
                    Text("Metric: \(metricName)")
                        .font(.subheadline)
                    TextField("Amount to add", text: $addedValue)
                        .keyboardType(.decimalPad)
                    TextField("Note (optional)", text: $note)
                }
                Section {
                    Button("Submit Update") {
                        submitUpdate()
                    }
                    .disabled(isSubmitting || addedValue.isEmpty)
                }
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Update Goal")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func submitUpdate() {
        guard let value = Double(addedValue), value > 0 else {
            errorMessage = "Please enter a valid number."
            return
        }
        isSubmitting = true
        errorMessage = nil

        let params: [String: Any] = [
            "goals_id": goalId,
            "added_value": value,
            "note": note
        ]
        guard let url = URL(string: "\(APIConfig.baseURL)/api/goals/update_filled_quota"),
              let body = try? JSONSerialization.data(withJSONObject: params) else {
            errorMessage = "Invalid request."
            isSubmitting = false
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
                isSubmitting = false
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