//
//  Chat.swift
//  Rep 
//
//  Created by Dmytro Holovko on 03.12.2023.
//

import SwiftUI
import ChatUI

struct Chat: View {
    let appearance = Appearance(tint: Color.green, localMessageBackground: .green)
    
    @State private var messages: [Message] = [
        Message.message5,
        Message.message4,
        Message.message2,
        Message.message1,
    ]
    
    var body: some View {
        ChannelStack(GroupChannel.channel1) {
            MessageList(messages) { message in
                MessageRow(
                    message: message,
                    showsUsername: false
                )
                .padding(.top, 12)
            }
            
            MessageField(options: [.menu], isMenuItemPresented: .constant(false)) {
                messages.insert(
                    Message(
                        id: UUID().uuidString,
                        sender: User.user1,
                        sentAt: Date().timeIntervalSince1970,
                        readReceipt: .delivered,
                        style: $0
                    ),
                    at: 0
                )
            }
        }
        .environmentObject(
            ChatConfiguration(
                userID: "andrew_parker",
                giphyKey: "wj5tEh9nAwNHVF3ZFavQ0zoaIyt8HZto"
            )
        )
        .environment(\.appearance, appearance)
    }
}

#Preview {
    Chat()
}


struct Message: MessageProtocol, Identifiable {
    var id: String
    var sender: User
    var sentAt: Double
    var editedAt: Double?
    var readReceipt: ReadReceipt
    var style: MessageStyle
}

extension Message {
    static let message1 = Message(
        id: UUID().uuidString,
        sender: User.bluebottle,
        sentAt: 1675331868,
        readReceipt: .seen,
        style: .text("Hi, there! I would like to ask about my order [#1920543](https://instagram.com/j_sung_0o0). Your agent mentioned that it would be available on [September 18](mailto:). However, I haven’t been notified yet by your company about my product availability. Could you provide me some news regarding it?")
    )
    
    static let message2 = Message(
        id: UUID().uuidString,
        sender: User.user1,
        sentAt: 1675342668,
        readReceipt: .seen,
        style: .text("Hi **Alexander**, we’re sorry to hear that. Could you give us some time to check on your order first? We will update you as soon as possible. Thanks!")
    )
    
    static let message4 = Message(
        id: UUID().uuidString,
        sender: User.bluebottle,
        sentAt: 1675334868,
        readReceipt: .seen,
        style: .text("Do you know what time is it?")
    )
    
    static let message5 = Message(
        id: UUID().uuidString,
        sender: User.bluebottle,
        sentAt: 1675338868,
        readReceipt: .seen,
        style: .text("What is the most popular meal in Japan?")
    )
}

struct User: UserProtocol {
    var id: String
    var username: String
    var imageURL: URL?
}

struct GroupChannel: ChannelProtocol {
    var id: String
    var name: String
    var imageURL: URL?
    var members: [User]
    var createdAt: Double
    var lastMessage: Message?
}

extension GroupChannel {
    static let channel1 = GroupChannel(
        id: User.bluebottle.id,
        name: User.bluebottle.username,
        imageURL: User.bluebottle.imageURL,
        members: [User.user1, User.bluebottle],
        createdAt: 1675242048,
        lastMessage: nil
    )
    
    static let new = GroupChannel(
        id: UUID().uuidString,
        name: User.user2.username,
        imageURL: nil,
        members: [User.user1, User.user2],
        createdAt: 1675860481,
        lastMessage: Message.message1
    )
}

extension User {
    static let user1 = User(
        id: "andrew_parker",
        username: "Andrew Parker",
        imageURL: URL(string: "https://images.pexels.com/photos/614810/pexels-photo-614810.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1")
    )
    
    static let user2 = User(
        id: "karen.castillo_96",
        username: "Karen Castillo",
        imageURL: URL(string: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxzZWFyY2h8Mnx8cGVyc29ufGVufDB8fDB8fA%3D%3D&w=1000&q=80")
    )
    
    static let noImage = User(
        id: "lucas.ganimi",
        username: "Lucas Ganimi"
    )
    
    static let starbucks = User(
        id: "starbucks",
        username: "Starbucks Coffee",
        imageURL: URL(string: "https://pbs.twimg.com/profile_images/1268570190855331841/CiNnNX94_400x400.jpg")
    )
    
    static let bluebottle = User(
        id: "bluebottle",
        username: "Blue Bottle Coffee",
        imageURL: URL(string: "https://pbs.twimg.com/profile_images/1514997622750138368/1mnEPbjo_400x400.jpg")
    )
}
