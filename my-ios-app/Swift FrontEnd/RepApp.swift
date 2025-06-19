//  RepApp.swift
//  Rep
//
//  Created by Adam Novak on 06.19.2025
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

import SwiftUI

@main
struct RepApp: App {
    @AppStorage("userId") var userId: Int = 0

    var body: some Scene {
        WindowGroup {
            if userId > 0 {
                MainScreen()
            } else {
                LoginView()
            }
        }
    }
}