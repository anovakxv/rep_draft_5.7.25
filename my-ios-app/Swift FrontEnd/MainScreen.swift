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
}

// MARK: - Unified User Model

struct User: Identifiable, Codable {
    let id: Int
    let fullName: String
    let fname: String?
    let lname: String?
    let username: String
    let about: String?
    let broadcast: String?
    let profilePictureURL: URL?
    let userType: String?
    let city: String?
    let skills: [String]?
    let lastLogin: String?
    let createdAt: String?
    let updatedAt: String?
    // Messaging fields
    let lastMessage: String?
    let lastMessageDate: String?

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case fname
        case lname
        case username
        case about
        case broadcast
        case profilePictureURL = "profile_picture_url"
        case userType = "user_type"
        case city
        case skills
        case lastLogin = "last_login"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastMessage = "last_message"
        case lastMessageDate = "last_message_date"
    }
}

// MARK: - API Responses

struct PortalsAPIResponse: Decodable {
    let result: [PortalModel]
}

struct UsersAPIResponse: Decodable {
    let results: [User]
}

// MARK: - ViewModels

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

class PeopleViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchUsers() {
        isLoading = true
        errorMessage = nil
        guard let url = URL(string: "http://localhost:5000/api/users/list") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.users = []
                    return
                }
                guard let data = data else {
                    self.errorMessage = "No data"
                    self.users = []
                    return
                }
                do {
                    let response = try JSONDecoder().decode(UsersAPIResponse.self, from: data)
                    self.users = response.results
                } catch {
                    self.errorMessage = "Failed to decode: \(error.localizedDescription)"
                    self.users = []
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
    @StateObject private var peopleVM = PeopleViewModel()
    @AppStorage("userId") var userId: Int = 0
    @State private var page: Page = .people
    @State private var section = 0

    var body: some View {
        NavigationStack {
            VStack {
                switch page {
                case .people:
                    if peopleVM.isLoading {
                        ProgressView("Loading people...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = peopleVM.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if peopleVM.users.isEmpty {
                        Text("No chats found.")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ChatList(users: peopleVM.users.sorted(by: { ($0.lastMessageDate ?? "") > ($1.lastMessageDate ?? "") }))
                    }
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
                    NavigationLink(destination: ProfileView()) {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .frame(width: Constants.imageSize, height: Constants.imageSize)
                            .clipShape(Circle())
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
                        } else {
                            peopleVM.fetchUsers()
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
            } else {
                peopleVM.fetchUsers()
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

// MARK: - Chat List (Unified User Model)

struct ChatList: View {
    var users: [User]

    var body: some View {
        if users.isEmpty {
            Text("No chats found.")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(users) { user in
                    HStack(alignment: .top, spacing: 0) {
                        // Profile Pic NavigationLink
                        NavigationLink(destination: ProfileView()) {
                            if let url = user.profilePictureURL {
                                AsyncImage(url: url) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Color.gray
                                }
                                .frame(width: 64, height: 64)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.crop.circle")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 64, height: 64)
                                    .clipShape(Circle())
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        // Chat Text NavigationLink
                        NavigationLink(destination: Chat(userId: user.id)) {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(user.fullName)
                                        .font(.subheadline)
                                    Spacer()
                                    if let dateString = user.lastMessageDate, let date = ISO8601DateFormatter().date(from: dateString) {
                                        Text(date.timeAgoDisplay())
                                            .font(.caption)
                                    }
                                }
                                Text(user.lastMessage ?? "")
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

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - Placeholder for PortalPage and Chat

struct PortalPage: View {
    let portalId: Int
    let userId: Int
    var body: some View {
        Text("Portal ID: \(portalId), User ID: \(userId)")
    }
}

struct Chat: View {
    let userId: Int
    var body: some
    