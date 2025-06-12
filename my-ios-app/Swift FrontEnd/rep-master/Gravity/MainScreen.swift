//
//  MainScreen.swift
//  Rep 
//
//  Created by Dmytro Holovko on 02.12.2023.
//

import SwiftUI

extension MainScreen {
    enum Page {
        case portals
        case people
    }
}

struct MainScreen: View {
    var chatItems1 = chatItems
    var portals1 = portals
    
    @State private var page: Page = .people
    @State private var section = 0
    
    var body: some View {
        NavigationStack {
            VStack {
                switch page {
                case .people:
                    ChatList(chatItems: chatItems1.sorted(by: {$0.lastMessageDate > $1.lastMessageDate}))
                case .portals:
                    PortalList(portals: portals1)
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("", selection: $section) {
                        Text("OPEN").tag(0)
                        Text("NTWK").tag(1)
                        Text("ALL").tag(2)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(destination: ProfileInfoView(viewModel: .init(profileInfo: pp))) {
                        GridItemView(size: Constants.imageSize, item: pp.image)
                            .clipShape(.circle)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(
                        action: {},
                        label: {
                            Image(systemName: "arrow.down")
                                .resizable()
                                .scaledToFill()
                                .frame(
                                    width: Constants.imageSize/1.5,
                                    height: Constants.imageSize/1.5
                                )
                                .accentColor(.green)
                        }
                    )
                }
            }
            .overlay(alignment: .bottomTrailing) {
                Button(
                    action: {
                        page = page == .people ? .portals : .people
                    },
                    label: {
                        Image("REPLogo")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 36.0, height: 36.0)
                    }
                )
                .padding(.trailing, 36)
                .padding(.bottom, 12)
            }
            .navigationBarBackButtonHidden()
        }
    }
}


struct ChatItemModel: Identifiable {
    let id = UUID()
    let imageName: String
    let name: String
    let lastMessage: String
    let lastMessageDate: Date
    
    var lastMessageDateFormatted: String {
        lastMessageDate.timeAgoDisplay()
    }
}

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}


struct ChatList: View {
    var chatItems: [ChatItemModel]
    
    var body: some View {
        List {
            ForEach(chatItems) { chatItem in
                VStack {
                    NavigationLink {
                        Chat()
                    } label: {
                        ChatItem(chatItem: chatItem)
                    }
                    Divider()
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
            }
        }
        .listStyle(.plain)
    }
}

struct ChatItem: View {
    var chatItem : ChatItemModel
    
    
    var body: some View {
        HStack(alignment: .top) {
            Image(chatItem.imageName)
                .resizable()
                .scaledToFill()
                .frame(
                    width: 64,
                    height: 64
                )
                .cornerRadius(100 / 2)
            VStack(alignment: .leading) {
                HStack {
                    Text(chatItem.name)
                        .font(.subheadline)
                    Spacer()
                    Text(chatItem.lastMessageDateFormatted)
                        .font(.caption)
                }
                Text(chatItem.lastMessage)
                    .font(.caption)
            }
        }
        .frame(height: 64)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}


struct PortalList: View {
    var portals: [PortalModel]
    
    var body: some View {
        List {
            ForEach(portals) { portal in
                VStack {
                    NavigationLink {
                        PortalPage(viewModel: PortalViewModel(portal: portal))
                    } label: {
                        PortalItem(portal: portal)
                    }
                    Divider()
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
            }
        }
        .listStyle(.plain)
    }
}

struct PortalItem: View {
    var portal: PortalModel
    
    var body: some View {
        HStack(alignment: .top) {
            // Portal image - 16:9 aspect ratio with height 64, no corner radius
            if let firstImage = portal.imageItems.first {
                ImageView(item: firstImage)
                    .frame(width: 64 * 16/9, height: 64) // 113.78 x 64 (16:9 ratio)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 64 * 16/9, height: 64) // 113.78 x 64 (16:9 ratio)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(portal.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text(portal.category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !portal.subtitle.isEmpty {
                    Text(portal.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack {
                    Text(portal.city)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(portal.leads.count) leads")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .frame(height: 64)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct PortalModel: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let about: String
    let category: String
    let city: String
    let imageItems: [ImageItem]
    let leads: [Lead]
    let goals: [GoalModel]
}

struct GoalModel: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let progress: Float // 0.0 to 1.0
}

struct Lead: Identifiable {
    let id = UUID()
    let name: String
    let image: ImageItem
}

//#Preview {
//    MainScreen()
//    ImageTabView(imageNames: portals.map {$0.imageName})
//    ChatItem(chatItem: .init(imageName: "leadPic", name: "Martin G.", lastMessage: "Hello Matt! Are you still there? ", lastMessageDate: Date().addingTimeInterval(-15000)))
//}







extension MainScreen {
    enum Constants {
        static let imageSize: CGFloat = 24.0
    }
}

struct ImageTabView: View {
    var imageItems: [ImageItem]
    
    @State private var selectedImageIndex: Int = 0
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black
                TabView(selection: $selectedImageIndex) {
                    ForEach(0..<imageItems.count, id: \.self) { index in
                        ZStack(alignment: .topLeading) {
                            ImageView(item: imageItems[index])
                                .tag(index)
                                .frame(height: 230)
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                if imageItems.count > 1 {
                    HStack(spacing: 4) {
                        ForEach(0..<imageItems.count, id: \.self) { index in
                            Capsule()
                                .fill(Color.white.opacity(selectedImageIndex == index ? 1 : 0.33))
                                .frame(width: proxy.size.width/CGFloat(imageItems.count) - 3, height: 2)
                                .onTapGesture {
                                    selectedImageIndex = index
                                }
                        }
                        .offset(y: -230/2 - 2)
                    }
                }
            }
        }
    }
}
