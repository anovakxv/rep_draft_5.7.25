//  GroupChatView.swift
//  Rep 
//
//  Created by Adam Novak on 06.19.2025
//  (c) 2025 Networked Capital Inc. All rights reserved.

import SwiftUI

// MARK: - Group Message Model

struct GroupMessage: Identifiable, Decodable {
    let id: Int
    let senderId: Int
    let senderName: String
    let senderPhotoURL: URL?
    let text: String
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case id
        case senderId = "sender_id"
        case senderName = "sender_name"
        case senderPhotoURL = "sender_photo_url"
        case text
        case timestamp
    }
}

// MARK: - Group Member Model

struct GroupMember: Identifiable, Decodable {
    let id: Int
    let name: String
    let photoURL: URL?

    enum CodingKeys: String, CodingKey {
        case id
        case name = "full_name"
        case photoURL = "profile_picture_url"
    }
}

// MARK: - API Response Models

struct GroupChatAPIResponse: Decodable {
    struct Result: Decodable {
        let chat: ChatInfo
        let users: [GroupMember]
        let messages: [GroupMessage]
    }
    let result: Result
}

struct ChatInfo: Decodable {
    let id: Int
    let name: String
    let description: String?
}

struct SendGroupMessageAPIResponse: Decodable {
    let result: String
    let message: GroupMessage
}

// MARK: - Group Chat ViewModel

class GroupChatViewModel: ObservableObject {
    @Published var messages: [GroupMessage] = []
    @Published var inputText: String = ""
    @Published var groupMembers: [GroupMember] = []
    @Published var groupName: String = ""

    let currentUserId: Int
    let chatId: Int

    @AppStorage("jwtToken") var jwtToken: String = ""

    init(currentUserId: Int, chatId: Int) {
        self.currentUserId = currentUserId
        self.chatId = chatId
        fetchGroupChat()
    }

    func fetchGroupChat() {
        guard let url = URL(string: "http://localhost:5000/api/group_chat?chats_id=\(chatId)&limit=50") else { return }
        var request = URLRequest(url: url)
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else { return }
            if let apiResult = try? JSONDecoder().decode(GroupChatAPIResponse.self, from: data) {
                DispatchQueue.main.async {
                    self.groupName = apiResult.result.chat.name
                    self.groupMembers = apiResult.result.users
                    self.messages = apiResult.result.messages
                }
            }
        }
        task.resume()
    }

    func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let url = URL(string: "http://localhost:5000/api/user/send_chat_message") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !jwtToken.isEmpty {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        let body: [String: Any] = [
            "chats_id": chatId,
            "message": trimmed
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else { return }
            if let apiResult = try? JSONDecoder().decode(SendGroupMessageAPIResponse.self, from: data) {
                DispatchQueue.main.async {
                    self.messages.append(apiResult.message)
                    self.inputText = ""
                }
            }
        }.resume()
    }
}

// MARK: - Group Chat View

struct GroupChatView: View {
    @ObservedObject var viewModel: GroupChatViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            StatusBarView()
            NavigationHeaderView(name: viewModel.groupName, onBack: { dismiss() })

            // Group Members Bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.groupMembers) { member in
                        VStack(spacing: 2) {
                            if let url = member.photoURL {
                                AsyncImage(url: url) { image in
                                    image.resizable().aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Circle().fill(Color.gray.opacity(0.3))
                                }
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 36, height: 36)
                            }
                            Text(member.name)
                                .font(.caption2)
                                .lineLimit(1)
                                .frame(width: 40)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .background(Color(UIColor.systemGray6))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(UIColor(red: 0.894, green: 0.894, blue: 0.894, alpha: 1.0))),
                alignment: .bottom
            )

            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            HStack(alignment: .bottom, spacing: 8) {
                                if message.senderId == viewModel.currentUserId {
                                    Spacer()
                                    GroupMessageBubble(message: message, isCurrentUser: true)
                                } else {
                                    // Profile pic for the sender
                                    if let url = message.senderPhotoURL {
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
                                    GroupMessageBubble(message: message, isCurrentUser: false)
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

            // Input Bar
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
                        .background(Color.repGreen)
                        .cornerRadius(20)
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
            viewModel.fetchGroupChat()
        }
    }
}

// MARK: - Group Message Bubble

struct GroupMessageBubble: View {
    let message: GroupMessage
    let isCurrentUser: Bool

    var body: some View {
        VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 2) {
            if !isCurrentUser {
                Text(message.senderName)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            Text(message.text)
                .padding(10)
                .background(isCurrentUser ? Color.repGreen : Color(UIColor.systemGray5))
                .foregroundColor(isCurrentUser ? .white : .black)
                .cornerRadius(16)
            Text(message.timestamp, style: .time)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: 260, alignment: isCurrentUser ? .trailing : .leading)
        .id(message.id)
    }
}

// MARK: - repGreen Color

extension Color {
    static let repGreen = Color(red: 0/255, green: 200/255, blue: 83/255)
}

// MARK: - Preview

struct GroupChatView_Previews: PreviewProvider {
    static var previews: some View {
        GroupChatView(
            viewModel: GroupChatViewModel(
                currentUserId: 1,
                chatId: 1
            )
        )
    }
}