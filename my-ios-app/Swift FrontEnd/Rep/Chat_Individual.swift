//  Chat.swift
//  Rep
//
//  Created by Adam Novak on 06.19.2025
//  (c) 2025 Networked Capital Inc. All rights reserved.

import SwiftUI

// MARK: - Message Model

struct SimpleMessage: Identifiable, Decodable {
    let id: Int
    let senderId: Int
    let senderName: String
    let text: String
    let timestamp: Date
    let read: String?

    enum CodingKeys: String, CodingKey {
        case id
        case senderId = "sender_id"
        case senderName = "sender_name"
        case text
        case timestamp
        case read
    }
}

// MARK: - API Response Models

struct GetMessagesAPIResponse: Decodable {
    struct Result: Decodable {
        let messages: [SimpleMessage]
    }
    let result: Result
}

struct SendMessageAPIResponse: Decodable {
    let result: String
    let message: SimpleMessage
}

// MARK: - Messaging ViewModel

class MessageViewModel: ObservableObject {
    @Published var messages: [SimpleMessage] = []
    @Published var inputText: String = ""
    
    let currentUserId: Int
    let otherUserId: Int
    let otherUserName: String
    let otherUserPhotoURL: URL?
    
    @AppStorage("jwtToken") var jwtToken: String = ""
    
    init(currentUserId: Int, otherUserId: Int, otherUserName: String, otherUserPhotoURL: URL?) {
        self.currentUserId = currentUserId
        self.otherUserId = otherUserId
        self.otherUserName = otherUserName
        self.otherUserPhotoURL = otherUserPhotoURL
    }
    
    func fetchMessages() {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/message/get_messages?users_id=\(otherUserId)&order=ASC&mark_as_read=1") else { return }
        var request = URLRequest(url: url)
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else { return }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let apiResult = try? decoder.decode(GetMessagesAPIResponse.self, from: data) {
                DispatchQueue.main.async {
                    self.messages = apiResult.result.messages
                }
            } else {
                print("Failed to decode messages: \(String(data: data, encoding: .utf8) ?? "")")
            }
        }
        task.resume()
    }
    
    func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let url = URL(string: "\(APIConfig.baseURL)/api/message/send_message") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        let body: [String: Any] = [
            "users_id": otherUserId,
            "message": trimmed
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else { return }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let apiResult = try? decoder.decode(SendMessageAPIResponse.self, from: data) {
                DispatchQueue.main.async {
                    self.messages.append(apiResult.message)
                    self.inputText = ""
                }
            } else {
                print("Failed to decode send message response: \(String(data: data, encoding: .utf8) ?? "")")
            }
        }.resume()
    }
}

// MARK: - Messaging View

struct MessageView: View {
    @ObservedObject var viewModel: MessageViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            NavigationHeaderView(name: viewModel.otherUserName, onBack: { dismiss() })
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            HStack(alignment: .bottom, spacing: 8) {
                                if message.senderId == viewModel.currentUserId {
                                    Spacer()
                                    MessageBubble(message: message, isCurrentUser: true, profilePicURL: nil)
                                } else {
                                    if let url = viewModel.otherUserPhotoURL {
                                        AsyncImage(url: url) { image in
                                            image.resizable().aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            SwiftUI.Circle().fill(Color.gray.opacity(0.3))
                                        }
                                        .frame(width: 32, height: 32)
                                        .clipShape(SwiftUI.Circle())
                                    } else {
                                        SwiftUI.Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 32, height: 32)
                                    }
                                    MessageBubble(message: message, isCurrentUser: false, profilePicURL: viewModel.otherUserPhotoURL)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                }
                .background(Color.white)
                .onChange(of: viewModel.messages.count) { _ in
                    if let last = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            HStack(spacing: 8) {
                TextField("Type a message...", text: $viewModel.inputText)
                    .padding(12)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(20)
                    .font(.body)
                Button(action: {
                    viewModel.sendMessage()
                }) {
                    Text("Send")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 18)
                        .background(SwiftUI.Color.repGreen)
                        .cornerRadius(8)
                }
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(UIColor(red: 0.894, green: 0.894, blue: 0.894, alpha: 1.0))),
                alignment: .top
            )
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
        .onAppear {
            viewModel.fetchMessages()
        }
        .navigationBarHidden(true) // Hide default nav bar and back button
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: SimpleMessage
    let isCurrentUser: Bool
    let profilePicURL: URL?
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isCurrentUser {
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(message.text)
                        .padding(10)
                        .background(Color.black)
                        .foregroundColor(Color.repGreen)
                        .cornerRadius(8)
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: 260, alignment: .trailing)
            } else {
                if let url = profilePicURL {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle().fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 32, height: 32)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(message.text)
                        .padding(10)
                        .background(Color(UIColor.systemGray5))
                        .foregroundColor(.black)
                        .cornerRadius(8)
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: 260, alignment: .leading)
                Spacer()
            }
        }
        .id(message.id)
    }
}


// MARK: - Preview

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        MessageView(
            viewModel: MessageViewModel(
                currentUserId: 1,
                otherUserId: 2,
                otherUserName: "Alex",
                otherUserPhotoURL: URL(string: "https://randomuser.me/api/portraits/men/32.jpg")
            )
        )
    }
}