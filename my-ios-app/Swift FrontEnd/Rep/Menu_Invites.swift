// Menu_Invites.swift
// Rep
//
//  Created by Adam Novak: August 2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.

import SwiftUI
import Kingfisher

// Original models remain the same
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

    var patchedInviterProfilePictureURL: URL? {
        guard let urlString = inviterPhotoURL, !urlString.isEmpty else { return nil }
        if urlString.starts(with: "http") {
            return URL(string: urlString)
        } else {
            let s3BaseURL = "https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/"
            let fullURL = s3BaseURL + urlString
            return URL(string: fullURL)
        }
    }
}

struct GoalTeamInvitesResponse: Codable {
    let invites: [GoalTeamInvite]
}

class GoalTeamInvitesManager: ObservableObject {
    static let shared = GoalTeamInvitesManager()
    
    @Published var pendingInvites: [GoalTeamInvite] = []
    @Published var isLoading: Bool = false
    
    @AppStorage("jwtToken") private var jwtToken: String = ""
    @AppStorage("userId") private var userId: Int = 0
    
    private init() { }
    
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
        
        let body: [String: Any] = ["action": action, "users": [userId]]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    completion(false)
                    return
                }
                completion(true)
            }
        }.resume()
    }

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
        URLSession.shared.dataTask(with: request) { [weak self] _, _, _ in
            DispatchQueue.main.async {
                self?.fetchPendingInvites()
                completion?()
            }
        }.resume()
    }
}

// UPDATED FOR SHEET PRESENTATION
struct InvitesView: View {
    // The callback passed from MainScreen
    var onDismiss: () -> Void
    
    // Keep the manager, but only to get initial data - no reactivity
    @State private var invites: [GoalTeamInvite] = []
    @State private var isLoading = true
    @State private var processingInviteId: Int? = nil
    
    @State private var alertMessage: String? = nil
    @State private var showAlert = false
    @State private var selectedGoalId: Int? = nil
    @State private var showGoalSheet = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        // Wrap in NavigationView for sheet presentation
        NavigationView {
            VStack {
                // Header - Updated for modal sheet presentation
                ZStack {
                    HStack {
                        Button(action: {
                            // First dismiss the view
                            dismiss()
                            
                            // After a brief delay, call onDismiss to refresh parent
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                onDismiss()
                            }
                        }) {
                            // Changed to X for modal sheet dismissal
                            Image(systemName: "xmark")
                                .foregroundColor(Color.repGreen)
                                .font(.system(size: 20))
                        }
                        .padding(.leading)
                        Spacer()
                    }
                    Text("Invitations").font(.headline).fontWeight(.semibold)
                }
                .padding(.vertical, 12)
                .background(Color.white)
                .overlay(Rectangle().frame(height: 1).foregroundColor(Color(UIColor.systemGray5)), alignment: .bottom)
                
                // Content
                if isLoading {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if invites.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle").font(.system(size: 60)).foregroundColor(.gray)
                        Text("No pending invitations").font(.title3).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Ultra-simple static list
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(invites) { invite in
                                InviteCard(
                                    invite: invite,
                                    isProcessing: processingInviteId == invite.id,
                                    onAccept: { handleAccept(invite) },
                                    onDecline: { handleDecline(invite) },
                                    onViewGoal: {
                                        selectedGoalId = invite.goals_id
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
                // Perform one-time loading on appear
                isLoading = true
                GoalTeamInvitesManager.shared.markAllInvitesRead()
                
                // Get data from manager (copy locally)
                invites = GoalTeamInvitesManager.shared.pendingInvites
                isLoading = false
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertMessage ?? ""), dismissButton: .default(Text("OK")) {
                    if invites.isEmpty {
                        // First dismiss
                        dismiss()
                        
                        // Then update parent
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            onDismiss()
                        }
                    }
                })
            }
            .fullScreenCover(isPresented: $showGoalSheet) {
                if let goalId = selectedGoalId {
                    NavigationView {
                        GoalsDetailView(initialGoal: Goal.placeholder.withId(goalId))
                    }
                }
            }
        }
        // Make sure sheet presentation looks good
        .edgesIgnoringSafeArea(.bottom)
    }
    
    private func handleAccept(_ invite: GoalTeamInvite) {
        processingInviteId = invite.id
        
        GoalTeamInvitesManager.shared.respondToInvite(goalId: invite.goals_id, action: "accept") { success in
            if success {
                alertMessage = "You've joined the goal team!"
                
                // Only update local state (no background updates)
                if let index = invites.firstIndex(where: { $0.id == invite.id }) {
                    invites.remove(at: index)
                }
                processingInviteId = nil
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showAlert = true
                }
            } else {
                alertMessage = "Failed to accept invite"
                processingInviteId = nil
                showAlert = true
            }
        }
    }
    
    private func handleDecline(_ invite: GoalTeamInvite) {
        processingInviteId = invite.id
        
        GoalTeamInvitesManager.shared.respondToInvite(goalId: invite.goals_id, action: "decline") { success in
            if success {
                alertMessage = "Invite declined"
                
                // Only update local state (no background updates)
                if let index = invites.firstIndex(where: { $0.id == invite.id }) {
                    invites.remove(at: index)
                }
                processingInviteId = nil
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showAlert = true
                }
            } else {
                alertMessage = "Failed to decline invite"
                processingInviteId = nil
                showAlert = true
            }
        }
    }
}

struct InviteCard: View {
    let invite: GoalTeamInvite
    var isProcessing: Bool = false
    var onAccept: () -> Void
    var onDecline: () -> Void
    var onViewGoal: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Goal Team Invite").font(.headline)
                    Text("\(invite.inviterDisplayName) invited you to join '\(invite.goalTitle ?? "a goal")'")
                        .font(.subheadline).foregroundColor(.secondary).lineLimit(2)
                }
                Spacer()
            }

            HStack(spacing: 12) {
                Button(action: onAccept) {
                    Text("Accept").fontWeight(.medium).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                        .background(isProcessing ? Color.repGreen.opacity(0.5) : Color.repGreen)
                        .cornerRadius(6)
                }.disabled(isProcessing)

                Button(action: onDecline) {
                    Text("Decline").fontWeight(.medium).foregroundColor(.black)
                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                        .background(isProcessing ? Color.gray.opacity(0.1) : Color.gray.opacity(0.2))
                        .cornerRadius(6)
                }.disabled(isProcessing)
            }

            Button(action: onViewGoal) {
                Text("View Goal").fontWeight(.medium)
                    .foregroundColor(Color(UIColor(red: 0.0, green: 0.4, blue: 0.0, alpha: 1.0)))
                    .frame(maxWidth: .infinity).padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1)).cornerRadius(6)
            }.disabled(isProcessing)
        }
        .padding(12).background(Color.white).cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .opacity(isProcessing ? 0.7 : 1.0)
    }
}