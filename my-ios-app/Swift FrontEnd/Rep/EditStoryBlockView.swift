//
//  EditStoryBlockView.swift
//  Rep
//
//  Created by Adam Novak on 12.09.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

import SwiftUI

struct EditStoryBlockView: View {
    @Environment(\.dismiss) private var dismiss

    let block: PortalWriteBlock?
    let onSave: (String?, String) -> Void
    let onCancel: () -> Void

    @State private var titleText: String
    @State private var contentText: String

    init(block: PortalWriteBlock?, onSave: @escaping (String?, String) -> Void, onCancel: @escaping () -> Void) {
        self.block = block
        self.onSave = onSave
        self.onCancel = onCancel
        _titleText = State(initialValue: block?.title ?? "")
        _contentText = State(initialValue: block?.content ?? "")
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Content area
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Title field
                        TextField("Title (optional)", text: $titleText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.headline)

                        // Content field
                        Text("Content")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextEditor(text: $contentText)
                            .font(.title3)
                            .frame(minHeight: 200)
                            .padding(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding()
                }
            }
            .navigationTitle(block == nil ? "Add Story Block" : "Edit Story Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(block == nil ? "Save" : "Update") {
                        let finalTitle = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(finalTitle.isEmpty ? nil : finalTitle, contentText)
                        dismiss()
                    }
                    .disabled(contentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.bold)
                }
            }
        }
    }
}
