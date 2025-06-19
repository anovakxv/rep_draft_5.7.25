//
//  MainScreen.swift
//  Rep 
//
//  Created by Dmytro Holovko on 02.12.2023.
//  Updated by Adam Novak on 06.19.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

import SwiftUI

// MARK: - Portal Model

struct PortalModel: Identifiable, Decodable {
    let id: Int
    let name: String
    let subtitle: String?
    let about: String?
    let categories_id: Int?
    let cities_id: Int?
    let lead_id: Int?
    let users_id: Int?
    let _c_users_count: Int?
    let mainImageUrl: String?
    // Add other fields as needed
}

struct PortalsAPIResponse: Decodable {
    let result: [PortalModel]
}

// MARK: - ViewModel

class PortalsViewModel: ObservableObject {
    @Published var portals: [PortalModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchPortals(userId: Int, section: Int) {
        isLoading = true
        errorMessage = nil
        var urlString = "http://localhost:5000/api/portals?users_id=\(userId)"
        // Section: 0 = OPEN, 1 = NTWK, 2 = ALL
        if section == 1 {
            urlString += "&my_network=1"
        } else if section == 2 {
            urlString += "&show_hidden=1"
        }
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.portals = []
                    return
                }
                guard let data = data else {
                    self.errorMessage = "No data"
                    self.portals = []
                    return
                }
                do {
                    let response = try JSONDecoder().decode(PortalsAPIResponse.self, from: data)
                    self.portals = response.result
                } catch {
                    self.errorMessage = "Failed to decode: \(error.localizedDescription)"
                    self.portals = []
                }
            }
        }.resume()
    }
}

// MARK: - MainScreen

extension MainScreen {
    enum Page {
        case portals
        case people
    }
    enum Constants {
        static let imageSize: CGFloat = 24.0
    }
}

struct MainScreen: View {
    @StateObject private var portalsVM = PortalsViewModel()
    @AppStorage("userId") var userId: Int = 0
    @State private var page: Page = .people
    @State private var section = 0

    // Placeholder chat data
    var chatItems1 = chatItems

    var body: some View {
        NavigationStack {
            VStack {
                switch page {
                case .people:
                    ChatList(chatItems: chatItems1.sorted(by: {$0.lastMessageDate > $1.lastMessageDate}))
                case .portals:
                    if portalsVM.isLoading {
                        ProgressView("Loading portals...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = portalsVM.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if portalsVM.portals.isEmpty {
                        Text("No portals found.")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        PortalList(portals: portalsVM.portals)
                    }
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
                    .onChange(of: section) { newSection in
                        if page == .portals {
                            portalsVM.fetchPortals(userId: userId, section: newSection)
                        }
                    }
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
                        if page == .portals {
                            portalsVM.fetchPortals(userId: userId, section: section)
                        }
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
        .onAppear {
            if page == .portals {
                portalsVM.fetchPortals(userId: userId, section: section)
            }
        }
    }
}

// MARK: - Portal List & Item

struct PortalList: View {
    var portals: [PortalModel]
    @AppStorage("userId") var userId: Int = 0

    var body: some View {
        List {
            ForEach(portals) { portal in
                VStack {
                    NavigationLink {
                        PortalPage(portalId: portal.id, userId: userId)
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
            if let urlString = portal.mainImageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(16/9, contentMode: .fill)
                } placeholder: {
                    Color.gray
                }
                .frame(width: 80, height: 45)
                .clipped()
            } else {
                Color.gray.frame(width: 80, height: 45).clipped()
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(portal.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text(portal.categories_id?.description ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if let subtitle = portal.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                HStack {
                    Text(portal.cities_id?.description ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(portal._c_users_count ?? 0) leads")
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

// MARK: - Chat List & Item (Placeholders)

struct ChatItemModel: Identifiable {
    let id = UUID()
    let userId: Int 
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
        if chatItems.isEmpty {
            Text("No chats found.")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(chatItems) { chatItem in
                    HStack(alignment: .top, spacing: 0) {
                        // Profile Pic NavigationLink
                        NavigationLink(destination: ProfileInfoView(userId: chatItem.userId)) {
                            Image(chatItem.imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 64, height: 64)
                                .cornerRadius(32)
                        }
                        .buttonStyle(PlainButtonStyle())
                        // Chat Text NavigationLink
                        NavigationLink(destination: Chat(userId: chatItem.userId)) {
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
                            .padding(.leading, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .frame(height: 64)
                    .padding(.vertical, 8)
                    Divider()
                }
            }
            .listStyle(.plain)
        }
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
