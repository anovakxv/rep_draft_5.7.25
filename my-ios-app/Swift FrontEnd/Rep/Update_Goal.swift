//  UpdateGoalSheet.swift
//  Rep
//
//  Created by Adam Novak on 07.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

import SwiftUI
import PhotosUI

struct UpdateGoalSheet: View {
    let goalId: Int
    let quota: Double
    let metricName: String

    @State private var addedValue: String = ""
    @State private var note: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    // Attachment state
    @State private var selectedImages: [UIImage] = []
    @State private var showImagePicker = false
    @State private var attachmentNotes: [String] = []

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
                Section(header: Text("Attachments")) {
                    Button {
                        showImagePicker = true
                    } label: {
                        Label {
                            Text("Add Photo (optional)")
                                .foregroundColor(Color(red: 0.549, green: 0.78, blue: 0.365)) // light rep green
                        } icon: {
                            Image(systemName: "photo")
                                .foregroundColor(Color(red: 0.549, green: 0.78, blue: 0.365)) // light rep green
                        }
                    }

                    // Show selected images
                    ForEach(selectedImages.indices, id: \.self) { index in
                        HStack {
                            Image(uiImage: selectedImages[index])
                                .resizable()
                                .scaledToFit()
                                .frame(height: 60)
                            TextField("Note for image", text: bindingForNote(at: index))
                            Button(action: {
                                selectedImages.remove(at: index)
                                attachmentNotes.remove(at: index)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
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
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImages: $selectedImages, attachmentNotes: $attachmentNotes)
            }
        }
    }

    // Helper to bind notes array safely
    private func bindingForNote(at index: Int) -> Binding<String> {
        if attachmentNotes.indices.contains(index) {
            return Binding(
                get: { attachmentNotes[index] },
                set: { attachmentNotes[index] = $0 }
            )
        } else {
            // If index doesn't exist, append empty string
            attachmentNotes.append("")
            return Binding(
                get: { attachmentNotes[index] },
                set: { attachmentNotes[index] = $0 }
            )
        }
    }

    private func submitUpdate() {
        guard let value = Double(addedValue), value > 0 else {
            errorMessage = "Please enter a valid number."
            return
        }
        isSubmitting = true
        errorMessage = nil

        let boundary = "Boundary-\(UUID().uuidString)"
        guard let url = URL(string: "\(APIConfig.baseURL)/api/goals/update_filled_quota") else {
            errorMessage = "Invalid request."
            isSubmitting = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "jwtToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let httpBody = NSMutableData()

        // Add text fields
        let fields: [String: String] = [
            "goals_id": "\(goalId)",
            "added_value": "\(value)",
            "note": note
        ]
        for (key, value) in fields {
            httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
            httpBody.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            httpBody.append("\(value)\r\n".data(using: .utf8)!)
        }

        // Add images
        for (index, image) in selectedImages.enumerated() {
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
                // Use "files" (no brackets) for every image
                httpBody.append("Content-Disposition: form-data; name=\"files\"; filename=\"image\(index).jpg\"\r\n".data(using: .utf8)!)
                httpBody.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
                httpBody.append(imageData)
                httpBody.append("\r\n".data(using: .utf8)!)

                // Use indexed field name for notes
                httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
                httpBody.append("Content-Disposition: form-data; name=\"sources_notes[\(index)]\"\r\n\r\n".data(using: .utf8)!)
                httpBody.append("\(index < attachmentNotes.count ? attachmentNotes[index] : "")\r\n".data(using: .utf8)!)
            }
        }

        // Add debug logging
        URLSession.shared.dataTask(with: request) { data, response, error in
            print("📤 Upload Response Code: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
            if let data = data, let responseStr = String(data: data, encoding: .utf8) {
                print("📤 Upload Response: \(responseStr)")
            }
        }

        // Close the HTTP body
        httpBody.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = httpBody as Data

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

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Binding var attachmentNotes: [String]
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 5
        config.filter = .images

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()

            for result in results {
                result.itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                    if let image = image as? UIImage {
                        DispatchQueue.main.async {
                            self.parent.selectedImages.append(image)
                            self.parent.attachmentNotes.append("")
                        }
                    }
                }
            }
        }
    }
}