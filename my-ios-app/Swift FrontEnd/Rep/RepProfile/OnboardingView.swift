//  OnboardingView.swift
//  Rep
//
//  Created by Adam Novak on 06.23.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.

import SwiftUI

struct OnboardingView: View {
    let userName: String
    let profileImage: UIImage?
    
    @State private var navigateToMainScreen = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                VStack(spacing: 0) {
                    // --- Top Bar (matches ProfileView) ---
                    HStack {
                        Spacer()
                        Text(userName)
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
                        if let image = profileImage {
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
                    Text("Hi, \(userName)!\n\nWe’re here to help you become your best self.\n\nWe do this by leveraging the people in your life who care about you, +AI.\n\nStart by viewing the list of “Purposes” and joining a Team.\n\nOr, search for someone you know and see what Goal Teams they’re on!")
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
                        navigateToMainScreen = true
                    }) {
                        Text("Find Goal Team to Join")
                            .font(.custom("Inter", size: 24).weight(.semibold))
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
        }
    }
}

// MARK: - Preview

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(userName: "Jose Barrera", profileImage: nil)
    }
}