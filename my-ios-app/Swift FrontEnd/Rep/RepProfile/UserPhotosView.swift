//
//  UserPhotosView.swift
//  Rep
//
//  Created by Adam Novak on 02.10.2026
//  Copyright (c) 2026 Networked Capital Inc. All rights reserved.
//

import SwiftUI
import Kingfisher
import PhotosUI

// MARK: - UserPhoto Model

struct UserPhoto: Identifiable, Codable {
    let id: Int
    var url: String?
    var caption: String?
    var position: Int?
    var created_at: String?
    var updated_at: String?
}

// MARK: - UserPhotosViewModel

@MainActor
class UserPhotosViewModel: ObservableObject {
    @Published var photos: [UserPhoto] = []
    @Published var isLoaded = false
    @Published var isUploading = false
    @Published var errorMessage: String?

    @AppStorage("jwtToken") var jwtToken: String = ""

    let userId: Int
    let isCurrentUser: Bool

    private var fetchTask: URLSessionDataTask?

    init(userId: Int, isCurrentUser: Bool) {
        self.userId = userId
        self.isCurrentUser = isCurrentUser
    }

    deinit {
        fetchTask?.cancel()
    }

    // MARK: - Fetch Photos

    func fetchPhotos() {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/user/photos?users_id=\(userId)") else { return }
        var request = URLRequest(url: url)
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }

        fetchTask?.cancel()
        fetchTask = URLSession.shared.dataTask(with: request) { [weak self] data, response, _ in
            if let http = response as? HTTPURLResponse {
                if http.statusCode == 401 || http.statusCode == 403 {
                    AuthSession.handleUnauthorized("UserPhotosViewModel.fetchPhotos")
                    return
                }
                if http.statusCode < 200 || http.statusCode >= 300 {
                    DispatchQueue.main.async {
                        self?.errorMessage = "Failed to load photos"
                        self?.isLoaded = true
                    }
                    return
                }
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    self?.isLoaded = true
                }
                return
            }
            do {
                let decoded = try JSONDecoder().decode([String: [UserPhoto]].self, from: data)
                DispatchQueue.main.async {
                    self?.photos = decoded["result"] ?? []
                    self?.isLoaded = true
                }
            } catch {
                print("UserPhotos fetch error:", error)
                DispatchQueue.main.async {
                    self?.errorMessage = "Failed to load photos"
                    self?.isLoaded = true
                }
            }
        }
        fetchTask?.resume()
    }

    // MARK: - Upload Photo

    func uploadPhoto(image: UIImage, caption: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/user/photos/upload") else {
            completion(false)
            return
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()

        // Caption field
        let trimmedCaption = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedCaption.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"caption\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(trimmedCaption)\r\n".data(using: .utf8)!)
        }

        // Photo file
        if let imageData = image.jpegData(compressionQuality: 0.85) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"user_photo.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        isUploading = true

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isUploading = false

                if let http = response as? HTTPURLResponse {
                    if http.statusCode == 401 || http.statusCode == 403 {
                        AuthSession.handleUnauthorized("UserPhotosViewModel.uploadPhoto")
                        completion(false)
                        return
                    }
                }

                guard let data = data, error == nil else {
                    completion(false)
                    return
                }

                // Decode the new photo from response
                do {
                    let decoded = try JSONDecoder().decode([String: UserPhoto].self, from: data)
                    if let newPhoto = decoded["result"] {
                        self?.photos.insert(newPhoto, at: 0)
                        completion(true)
                    } else {
                        completion(false)
                    }
                } catch {
                    print("Upload decode error:", error)
                    // Still refresh photos from server as fallback
                    self?.fetchPhotos()
                    completion(true)
                }
            }
        }.resume()
    }

    // MARK: - Delete Photo

    func deletePhoto(id: Int) {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/user/photos/\(id)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }

        URLSession.shared.dataTask(with: request) { [weak self] _, response, _ in
            if let http = response as? HTTPURLResponse {
                if http.statusCode == 401 || http.statusCode == 403 {
                    AuthSession.handleUnauthorized("UserPhotosViewModel.deletePhoto")
                    return
                }
            }
            DispatchQueue.main.async {
                self?.photos.removeAll { $0.id == id }
            }
        }.resume()
    }

    // MARK: - Reorder Photos

    func movePhotoUp(at index: Int) {
        guard index > 0 else { return }
        photos.swapAt(index, index - 1)
        savePhotoOrder()
    }

    func movePhotoDown(at index: Int) {
        guard index < photos.count - 1 else { return }
        photos.swapAt(index, index + 1)
        savePhotoOrder()
    }

    private func savePhotoOrder() {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/user/photos/reorder") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }

        let photoOrder = photos.enumerated().map { idx, photo in
            ["id": photo.id, "position": idx]
        }
        let body: [String: Any] = [
            "users_id": userId,
            "photo_order": photoOrder
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { _, response, _ in
            if let http = response as? HTTPURLResponse {
                if http.statusCode == 401 || http.statusCode == 403 {
                    AuthSession.handleUnauthorized("UserPhotosViewModel.savePhotoOrder")
                }
            }
        }.resume()
    }
}

// MARK: - UserPhotosView

struct UserPhotosView: View {
    @StateObject private var viewModel: UserPhotosViewModel
    @Environment(\.dismiss) private var dismiss

    // Upload state
    @State private var showUploadSheet = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var uploadImage: UIImage?
    @State private var uploadCaption = ""
    @State private var uploadError: String?

    // Edit mode
    @State private var isEditing = false

    // Delete state
    @State private var deleteTarget: UserPhoto?
    @State private var showDeleteAlert = false

    // Fullscreen viewer
    @State private var fullscreenIndex: Int?

    init(userId: Int, isCurrentUser: Bool) {
        _viewModel = StateObject(wrappedValue: UserPhotosViewModel(userId: userId, isCurrentUser: isCurrentUser))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                        .font(.system(size: 20))
                }
                Spacer()
                Text("Photos")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
                if viewModel.isCurrentUser {
                    HStack(spacing: 16) {
                        Button(action: { isEditing.toggle() }) {
                            Text(isEditing ? "Done" : "Edit")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                        }
                        Button(action: { showUploadSheet = true }) {
                            Image(systemName: "plus")
                                .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                                .font(.system(size: 20))
                        }
                    }
                } else {
                    // Spacer for symmetry
                    Color.clear.frame(width: 24, height: 24)
                }
            }
            .frame(height: 56)
            .padding(.horizontal, 15)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(UIColor(red: 0.894, green: 0.894, blue: 0.894, alpha: 1.0))),
                alignment: .bottom
            )

            // Content
            if !viewModel.isLoaded {
                Spacer()
                ProgressView()
                Spacer()
            } else if let error = viewModel.errorMessage {
                Spacer()
                Text(error)
                    .foregroundColor(.red)
                    .padding()
                Button("Retry") {
                    viewModel.errorMessage = nil
                    viewModel.fetchPhotos()
                }
                .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                Spacer()
            } else if viewModel.photos.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.4))
                    Text("No photos yet")
                        .foregroundColor(.secondary)
                    if viewModel.isCurrentUser {
                        Button("Add Photo") {
                            showUploadSheet = true
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                        .cornerRadius(10)
                    }
                }
                Spacer()
            } else {
                // Photo Feed
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(viewModel.photos.enumerated()), id: \.element.id) { index, photo in
                            VStack(spacing: 0) {
                                // Reorder & Delete Controls (owner only)
                                if viewModel.isCurrentUser && isEditing {
                                    HStack {
                                        // Reorder buttons
                                        HStack(spacing: 4) {
                                            if index > 0 {
                                                Button(action: { viewModel.movePhotoUp(at: index) }) {
                                                    Image(systemName: "chevron.up")
                                                        .foregroundColor(.gray)
                                                }
                                            }
                                            if index < viewModel.photos.count - 1 {
                                                Button(action: { viewModel.movePhotoDown(at: index) }) {
                                                    Image(systemName: "chevron.down")
                                                        .foregroundColor(.gray)
                                                }
                                            }
                                        }
                                        Spacer()
                                        // Delete button
                                        Button(action: {
                                            deleteTarget = photo
                                            showDeleteAlert = true
                                        }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                }

                                // Photo Image
                                if let urlString = photo.url, let url = URL(string: urlString) {
                                    KFImage(url)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: .infinity)
                                        .background(Color(UIColor.systemGray6))
                                        .onTapGesture {
                                            fullscreenIndex = index
                                        }
                                }

                                // Caption + Timestamp
                                if photo.caption != nil || photo.created_at != nil {
                                    VStack(alignment: .leading, spacing: 4) {
                                        if let caption = photo.caption, !caption.isEmpty {
                                            Text(caption)
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                        }
                                        if let dateStr = photo.created_at {
                                            Text(formatDate(dateStr))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                }
                            }
                            .background(Color.white)
                        }
                    }
                    .padding(.bottom, 80)
                }
            }
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
        .navigationBarHidden(true)
        .onAppear {
            if !viewModel.isLoaded {
                viewModel.fetchPhotos()
            }
        }
        // Upload Sheet
        .sheet(isPresented: $showUploadSheet) {
            UploadPhotoSheet(
                viewModel: viewModel,
                isPresented: $showUploadSheet
            )
        }
        // Delete Alert
        .alert("Delete Photo", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let photo = deleteTarget {
                    viewModel.deletePhoto(id: photo.id)
                    deleteTarget = nil
                }
            }
            Button("Cancel", role: .cancel) {
                deleteTarget = nil
            }
        } message: {
            Text("This can't be undone.")
        }
        // Fullscreen Viewer
        .fullScreenCover(item: $fullscreenIndex) { index in
            PhotoFullscreenViewer(
                photos: viewModel.photos,
                startIndex: index
            )
        }
    }

    // MARK: - Date Formatting

    private func formatDate(_ dateStr: String) -> String {
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MM-dd-yyyy h:mma zzz"

        // Try format: "2025-12-07T22:04:30.052298" (with microseconds, no timezone)
        let microsecondFormatter = DateFormatter()
        microsecondFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        microsecondFormatter.timeZone = TimeZone(identifier: "UTC")
        if let date = microsecondFormatter.date(from: dateStr) {
            return outputFormatter.string(from: date)
        }

        // Try ISO8601 format with timezone (e.g., "2025-12-07T22:04:30Z")
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: dateStr) {
            return outputFormatter.string(from: date)
        }

        // Try fallback format: "yyyy-MM-dd HH:mm:ss"
        let fallbackFormatter = DateFormatter()
        fallbackFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        fallbackFormatter.timeZone = TimeZone(identifier: "UTC")
        if let date = fallbackFormatter.date(from: dateStr) {
            return outputFormatter.string(from: date)
        }

        return dateStr
    }
}

// MARK: - Int Identifiable (for fullscreen cover)

extension Int: @retroactive Identifiable {
    public var id: Int { self }
}

// MARK: - Upload Photo Sheet

struct UploadPhotoSheet: View {
    @ObservedObject var viewModel: UserPhotosViewModel
    @Binding var isPresented: Bool

    @State private var photoPickerItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var caption = ""
    @State private var uploadError: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                if let image = selectedImage {
                    // Preview
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(8)
                        .padding(.horizontal)

                    // Caption input
                    TextField("Write a caption...", text: $caption)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    Text("\(caption.count)/500")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal)

                    if viewModel.isUploading {
                        ProgressView("Uploading...")
                    }

                    if let error = uploadError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                } else {
                    Spacer()
                    PhotosPicker(
                        selection: $photoPickerItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 40))
                                .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                            Text("Select Photo")
                                .font(.headline)
                                .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                        }
                    }
                    Spacer()
                }

                Spacer()
            }
            .navigationTitle("New Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.isUploading ? "Posting..." : "Post") {
                        guard let image = selectedImage else { return }
                        uploadError = nil
                        viewModel.uploadPhoto(image: image, caption: caption) { success in
                            if success {
                                isPresented = false
                            } else {
                                uploadError = "Upload failed. Please try again."
                            }
                        }
                    }
                    .disabled(selectedImage == nil || viewModel.isUploading)
                    .foregroundColor(selectedImage != nil && !viewModel.isUploading
                        ? Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0))
                        : .gray)
                }
            }
            .onChange(of: photoPickerItem) { newItem in
                guard let item = newItem else { return }
                item.loadTransferable(type: Data.self) { result in
                    switch result {
                    case .success(let data):
                        if let data, let image = UIImage(data: data) {
                            DispatchQueue.main.async {
                                self.selectedImage = image
                            }
                        }
                    case .failure(let error):
                        print("Failed to load image: \(error)")
                    }
                }
            }
        }
    }
}

// MARK: - Photo Fullscreen Viewer

struct PhotoFullscreenViewer: View {
    let photos: [UserPhoto]
    @State var startIndex: Int
    @Environment(\.dismiss) private var dismiss

    @State private var currentIndex: Int = 0

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            TabView(selection: $currentIndex) {
                ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                    if let urlString = photo.url, let url = URL(string: urlString) {
                        KFImage(url)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .tag(index)
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: photos.count > 1 ? .always : .never))

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 8)
                }
                Spacer()

                // Caption
                if let caption = photos[safe: currentIndex]?.caption, !caption.isEmpty {
                    Text(caption)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.clear, .black.opacity(0.6)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                // Counter
                if photos.count > 1 {
                    Text("\(currentIndex + 1) / \(photos.count)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, 8)
                }
            }
        }
        .onAppear {
            currentIndex = startIndex
        }
        .statusBarHidden(true)
    }
}

// MARK: - Safe Array Access

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
