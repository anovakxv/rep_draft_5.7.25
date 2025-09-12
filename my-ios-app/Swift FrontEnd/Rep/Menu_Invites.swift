// Menu_Invites.swift
// Rep
//
//  Created by Adam Novak: August 2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.

// MARK: - Goal Team Invite Model

import SwiftUI
import Kingfisher

struct GoalTeamInvite: Identifiable, Codable, Equatable {
    let id: Int
    let goals_id: Int
    let users_id1: Int
    let users_id2: Int
    let confirmed: Int
    let read1: Bool
    let read2: Bool
    let timestamp: String?

    let goalTitle: String?
    let inviterName: String?
    let inviterPhotoURL: String?

    var inviterDisplayName: String {
        inviterName ?? "Someone"
    }

    // Improved patching logic with direct S3 base URL reference
    var patchedInviterProfilePictureURL: URL? {
        guard let urlString = inviterPhotoURL, !urlString.isEmpty else { return nil }
        
        // Debug print to see the actual URL value
        print("Profile URL before patching: \(urlString)")
        
        if urlString.starts(with: "http") {
            return URL(string: urlString)
        } else {
            let s3BaseURL = "https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/"
            let fullURL = s3BaseURL + urlString
            print("Profile URL after patching: \(fullURL)")
            return URL(string: fullURL)
        }
    }
}

struct GoalTeamInvitesResponse: Codable {
    let invites: [GoalTeamInvite]
}

// Singleton manager to handle invites across the app
class GoalTeamInvitesManager: ObservableObject {
    static let shared = GoalTeamInvitesManager()
    
    @Published var pendingInvites: [GoalTeamInvite] = []
    @Published var isLoading: Bool = false
    
    @AppStorage("jwtToken") private var jwtToken: String = ""
    @AppStorage("userId") private var userId: Int = 0
    
    private init() {
        // Initialize with empty data
    }
    
    func fetchPendingInvites() {
        guard !jwtToken.isEmpty, userId != 0 else { return }
        isLoading = true
        
        guard let url = URL(string: "\(APIConfig.baseURL)/api/goals/pending_invites") else {
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                guard let data = data else { return }
                do {
                    let response = try JSONDecoder().decode(GoalTeamInvitesResponse.self, from: data)
                    self?.pendingInvites = response.invites.filter { $0.confirmed == 0 }
                    
                    // Debug: Print the received invites to check photo URLs
                    for invite in response.invites {
                        print("Invite from: \(invite.inviterName ?? "Unknown"), Photo URL: \(invite.inviterPhotoURL ?? "None")")
                    }
                } catch {
                    print("Error decoding invites:", error)
                }
            }
        }.resume()
    }
    
    func respondToInvite(goalId: Int, action: String, completion: @escaping (Bool) -> Void) {
        guard !jwtToken.isEmpty, userId != 0 else {
            completion(false)
            return
        }
        
        guard let url = URL(string: "\(APIConfig.baseURL)/api/goals/\(goalId)/team") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "action": action, // "accept" or "decline"
            "users": [userId]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(false)
                    return
                }
                
                let success = httpResponse.statusCode >= 200 && httpResponse.statusCode < 300
                
                if success {
                    // Remove the invite from the list
                    self?.pendingInvites.removeAll { $0.goals_id == goalId }
                }
                
                completion(success)
            }
        }.resume()
    }

    // MARK: - Mark all invites as read when viewing
    func markAllInvitesRead(completion: (() -> Void)? = nil) {
        guard !jwtToken.isEmpty, userId != 0 else {
            completion?()
            return
        }
        guard let url = URL(string: "\(APIConfig.baseURL)/api/goals/pending_invites/mark_read") else {
            completion?()
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                // Refresh invites after marking as read
                self?.fetchPendingInvites()
                completion?()
            }
        }.resume()
    }
}

struct InvitesView: View {
    @ObservedObject private var invitesManager = GoalTeamInvitesManager.shared
    @State private var responseMessage: String? = nil
    @State private var showAlert = false
    @State private var selectedGoalId: Int? = nil
    @State private var showGoalSheet = false // New state for sheet
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            // Header
            ZStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color.repGreen)
                            .font(.system(size: 20))
                    }
                    .padding(.leading)
                    Spacer()
                }
                
                Text("Invitations")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .padding(.vertical, 12)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(UIColor.systemGray5)),
                alignment: .bottom
            )
            
            if invitesManager.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if invitesManager.pendingInvites.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No pending invitations")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(invitesManager.pendingInvites) { invite in
                            InviteCard(
                                invite: invite,
                                onAccept: {
                                    invitesManager.respondToInvite(goalId: invite.goals_id, action: "accept") { success in
                                        responseMessage = success ? "You've joined the goal team!" : "Failed to accept invite"
                                        showAlert = true
                                    }
                                },
                                onDecline: {
                                    invitesManager.respondToInvite(goalId: invite.goals_id, action: "decline") { success in
                                        responseMessage = success ? "Invite declined" : "Failed to decline invite"
                                        showAlert = true
                                    }
                                },
                                onViewGoal: {
                                    print("📱 View Goal tapped for goal ID: \(invite.goals_id)")
                                    selectedGoalId = invite.goals_id
                                    // Show the sheet instead of using NavigationLink
                                    showGoalSheet = true
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            invitesManager.markAllInvitesRead()
            invitesManager.fetchPendingInvites() // Ensure we fetch fresh data
        }
        .alert(isPresented: $showAlert, content: {
            Alert(title: Text(responseMessage ?? ""))
        })
        // Use a sheet instead of NavigationLink for more reliable navigation
        .fullScreenCover(isPresented: $showGoalSheet, onDismiss: {
            // Reset navigation state when sheet is dismissed
            selectedGoalId = nil
            print("📱 Goal sheet dismissed")
        }) {
            if let goalId = selectedGoalId {
                NavigationView {
                    GoalsDetailView(initialGoal: Goal.placeholder.withId(goalId))
                        .onAppear {
                            print("📱 GoalsDetailView appeared with ID: \(goalId)")
                        }
                }
            }
        }
    }
}

struct InviteCard: View {
    let invite: GoalTeamInvite
    var onAccept: () -> Void
    var onDecline: () -> Void
    var onViewGoal: () -> Void // <-- Added callback for navigation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                // Enhanced profile picture loading
                // Profile picture removed for now

                VStack(alignment: .leading, spacing: 2) {
                    Text("Goal Team Invite")
                        .font(.headline)

                    Text("\(invite.inviterDisplayName) invited you to join '\(invite.goalTitle ?? "a goal")'")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }

            HStack(spacing: 12) {
                Button(action: onAccept) {
                    Text("Accept")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.repGreen)
                        .cornerRadius(6)
                }

                Button(action: onDecline) {
                    Text("Decline")
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(6)
                }
            }

            // "View Goal" button
            Button(action: onViewGoal) {
                Text("View Goal")
                    .fontWeight(.medium)
                    .foregroundColor(Color(UIColor(red: 0.0, green: 0.4, blue: 0.0, alpha: 1.0))) // dark green
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}