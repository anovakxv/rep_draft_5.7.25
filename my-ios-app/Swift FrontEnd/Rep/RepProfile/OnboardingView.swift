//  Rep
//
//  Created by Adam Novak: July 2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

import SwiftUI

struct OnboardingView: View {
    let userName: String
    let profileImage: UIImage?
    
    @State private var navigateToMainScreen = false
    @AppStorage("isRegistered") var isRegistered: Bool = false
    @AppStorage("onboardingComplete") var onboardingComplete: Bool = false
    @AppStorage("pendingUserId") var pendingUserId: Int = 0
    @AppStorage("userId") var userId: Int = 0

    // --- For fetching latest profile info ---
    @State private var profilePictureURL: URL? = nil
    @State private var fetchedUserName: String? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                VStack(spacing: 0) {
                    // --- Top Bar (matches ProfileView) ---
                    HStack {
                        Spacer()
                        Text(fetchedUserName ?? userName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                        Spacer()
                        Color.clear.frame(width: 24, height: 24)
                    }
                    .frame(height: 44)
                    .padding(.horizontal, 15)
                    .background(Color.white)
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color(UIColor(red: 0.894, green: 0.894, blue: 0.894, alpha: 1.0))),
                        alignment: .bottom
                    )

                    // --- Profile Picture (matches ProfileInfoView) ---
                    ZStack {
                        if let url = profilePictureURL {
                            AsyncImage(url: url) { image in
                                image.resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle().fill(Color.gray.opacity(0.3))
                            }
                            .frame(width: 108, height: 108)
                            .clipShape(Circle())
                        } else if let image = profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 108, height: 108)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 108, height: 108)
                                .overlay(
                                    Image(systemName: "person.crop.circle")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 80, height: 80)
                                        .foregroundColor(.white.opacity(0.7))
                                )
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 16)

                    // --- Welcome Message ---
                    Text("Hi, \(fetchedUserName ?? userName)!\n\nWe’re here to help you become your best self.\n\nWe do this by leveraging the people in your life who care about you, +AI.\n\nStart by viewing the list of “Purposes” and joining a Team.\n\nOr, search for someone you know and see what Goal Teams they’re on!")
                        .font(.custom("Inter", size: 20))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(8)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)

                    Spacer()

                    // --- NavigationLink to MainScreen ---
                    NavigationLink(
                        destination: MainScreen()
                            .navigationBarBackButtonHidden(true),
                        isActive: $navigateToMainScreen
                    ) {
                        EmptyView()
                    }

                    // --- Action Button ---
                    Button(action: {
                        userId = pendingUserId      // <-- Set the real userId here
                        pendingUserId = 0           // <-- Optionally clear pendingUserId
                        isRegistered = true
                        onboardingComplete = true
                        navigateToMainScreen = true
                    }) {
                        Text("find Goal Team to join")
                            .font(.custom("Inter", size: 24).weight(.bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                            .background(Color(red: 0.48, green: 0.75, blue: 0.29))
                            .cornerRadius(14)
                            .shadow(color: Color.black.opacity(0.25), radius: 4, y: 4)
                            .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationBarBackButtonHidden(true)
            .onAppear {
                fetchUserProfile()
            }
        }
    }

    // --- Fetch latest user profile to get profile picture URL and name ---
    private func fetchUserProfile() {
        // Use pendingUserId if set, otherwise fallback to userId
        let idToFetch = pendingUserId != 0 ? pendingUserId : userId
        guard idToFetch != 0,
              let url = URL(string: "\(APIConfig.baseURL)/api/user/profile?users_id=\(idToFetch)"),
              let token = UserDefaults.standard.string(forKey: "jwtToken") else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let apiResponse = try? JSONDecoder().decode(UserProfileAPIResponse.self, from: data) else { return }
            DispatchQueue.main.async {
                self.profilePictureURL = apiResponse.result.profilePictureURL
                // Prefer fullName, fallback to fname/lname, fallback to passed-in userName
                if let fullName = apiResponse.result.fullName, !fullName.isEmpty {
                    self.fetchedUserName = fullName
                } else if let fname = apiResponse.result.fname, let lname = apiResponse.result.lname {
                    self.fetchedUserName = "\(fname) \(lname)".trimmingCharacters(in: .whitespaces)
                }
            }
        }.resume()
    }
}

// MARK: - Preview

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(userName: "Jose Barrera", profileImage: nil)
    }
}
