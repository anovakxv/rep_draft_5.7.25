//
//  EditWriteBlockView.swift
//  Rep
//
//  Created by Adam Novak on 12.09.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

import SwiftUI

struct EditWriteBlockView: View {
    @Environment(\.dismiss) private var dismiss

    let write: WriteBlock?
    let onSave: (String?, String) -> Void
    let onCancel: () -> Void

    @State private var titleText: String
    @State private var contentText: String

    init(write: WriteBlock?, onSave: @escaping (String?, String) -> Void, onCancel: @escaping () -> Void) {
        self.write = write
        self.onSave = onSave
        self.onCancel = onCancel
        _titleText = State(initialValue: write?.title ?? "")
        _contentText = State(initialValue: write?.content ?? "")
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 12) {
                // Title field
                TextField("Title (optional)", text: $titleText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 8)

                // Content field - fills remaining space
                VStack(alignment: .leading, spacing: 4) {
                    Text("Content")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    TextEditor(text: $contentText)
                        .font(.title3)
                        .padding(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal)
                }
                .frame(maxHeight: .infinity)

                Spacer(minLength: 8)
            }
            .navigationTitle(write == nil ? "Add Write Block" : "Edit Write Block")
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
                    Button(write == nil ? "Save" : "Update") {
                        let finalTitle = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(finalTitle.isEmpty ? nil : finalTitle, contentText)
                        dismiss()
                    }
                    .disabled(contentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                    .fontWeight(.bold)
                }
            }
        }
    }
}
