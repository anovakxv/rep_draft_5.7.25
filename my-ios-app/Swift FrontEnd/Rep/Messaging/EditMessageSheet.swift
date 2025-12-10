//
//  EditMessageSheet.swift
//  Rep
//
//  Created by Adam Novak on 12.09.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

import SwiftUI

struct EditMessageSheet: View {
    @Environment(\.dismiss) private var dismiss

    let originalText: String
    let onSave: (String) -> Void
    let onCancel: () -> Void

    @State private var editedText: String

    init(originalText: String, onSave: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.originalText = originalText
        self.onSave = onSave
        self.onCancel = onCancel
        _editedText = State(initialValue: originalText)
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 12) {
                // Message text editor
                TextEditor(text: $editedText)
                    .font(.body)
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .frame(minHeight: 120)

                Spacer()
            }
            .navigationTitle("Edit Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                    .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmedText = editedText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmedText.isEmpty {
                            onSave(trimmedText)
                            dismiss()
                        }
                    }
                    .disabled(editedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                    .fontWeight(.bold)
                }
            }
        }
    }
}
