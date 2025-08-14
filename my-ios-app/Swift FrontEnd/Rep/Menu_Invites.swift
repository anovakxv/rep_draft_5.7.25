// Menu_Invites.swift
// Rep
//
//  Created by Adam Novak: August 2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.

// MARK: - Goal Team Invite Model

import SwiftUI
import Kingfisher

struct GoalTeamInvite: Identifiable, Codable {
    let id: Int
    let goals_id: Int
    let users_id1: Int // inviter
    let users_id2: Int // invitee (current user)
    let confirmed: Int // 0=pending, 1=accepted, -1=declined
    let read1: Bool
    let read2: Bool
    let timestamp: String?
    
    // Additional fields from joined data
    let goalTitle: String?
    let inviterName: String?
    let inviterPhotoURL: String?
    
    var inviterDisplayName: String {
        return inviterName ?? "Someone"
    }
    
    var inviterProfilePictureURL: URL? {
        guard let urlString = inviterPhotoURL, !urlString.isEmpty else { return nil }
        if urlString.starts(with: "http") {
            return URL(string: urlString)
        } else {
            return URL(string: "https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/\(urlString)")
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
}

struct InvitesView: View {
    @ObservedObject private var invitesManager = GoalTeamInvitesManager.shared
    @State private var responseMessage: String? = nil
    @State private var showAlert = false
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
            invitesManager.fetchPendingInvites()
        }
        .alert(isPresented: $showAlert, content: {
            Alert(title: Text(responseMessage ?? ""))
        })
    }
}

struct InviteCard: View {
    let invite: GoalTeamInvite
    var onAccept: () -> Void
    var onDecline: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                // Inviter photo
                if let url = invite.inviterProfilePictureURL {
                    KFImage(url)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)
                }
                
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
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}
