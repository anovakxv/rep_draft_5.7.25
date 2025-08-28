//  OnboardingView.swift (container + walkthrough)
//  Rep
//
//  Created by Adam Novak on 8.27.2025
//  Replaces the old single-screen OnboardingView with:
//  - OnboardingFlowEntryView: profile -> terms -> walkthrough
//  - AppWalkthroughView: 5-screen walkthrough
//

import SwiftUI
import Combine

// MARK: - Entry Container (Profile -> Terms -> Walkthrough)

struct OnboardingFlowEntryView: View {
    @AppStorage("onboardingUserName") private var onboardingUserName: String = ""
    @AppStorage("onboardingProfileImageData") private var onboardingProfileImageData: Data?
    @AppStorage("acceptedTermsOfUse") private var acceptedTermsOfUse: Bool = false
    
    @AppStorage("isRegistered") private var isRegistered: Bool = false
    @AppStorage("onboardingComplete") private var onboardingComplete: Bool = false
    @AppStorage("pendingUserId") private var pendingUserId: Int = 0
    @AppStorage("userId") private var userId: Int = 0

    enum OnboardingStep { case profile, terms, walkthrough }
    @State private var step: OnboardingStep = .profile

    @StateObject private var onboardingProfileVM = ProfileInfoViewModel(
        profileInfo: ProfileInfo(
            firstName: "",
            lastName: "",
            skills: [],
            type: .lead,
            cityName: "",
            image: nil,
            about: "",
            broadcast: "",
            otherSkill: ""
        ),
        mode: .edit
    )

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .profile:
                    EditProfileView(
                        viewModel: onboardingProfileVM,
                        showOnboardingAfterSave: true,
                        onSave: { _ in
                            onboardingUserName = (onboardingProfileVM.profileInfo.firstName + " " + onboardingProfileVM.profileInfo.lastName)
                                .trimmingCharacters(in: .whitespaces)
                            if let image = onboardingProfileVM.profileInfo.image,
                               let data = image.jpegData(compressionQuality: 0.8) {
                                onboardingProfileImageData = data
                            }
                            if !acceptedTermsOfUse {
                                step = .terms
                            } else {
                                step = .walkthrough
                            }
                        }
                    )
                case .terms:
                    TermsOfUseView {
                        acceptedTermsOfUse = true
                        step = .walkthrough
                    }
                case .walkthrough:
                    AppWalkthroughView(
                        onSkip: { completeOnboarding() },
                        onFinish: { completeOnboarding() }
                    )
                }
            }
        }
    }

    private func completeOnboarding() {
        print("Walkthrough Complete/Skip: userId before: \(userId), pendingUserId: \(pendingUserId), onboardingComplete: \(onboardingComplete)")
        userId = pendingUserId
        pendingUserId = 0
        isRegistered = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            print("Setting onboardingComplete = true")
            onboardingComplete = true
            NotificationCenter.default.post(name: Notification.Name("ForceRootReload"), object: nil)
            print("Walkthrough Completed: userId after: \(userId), onboardingComplete: \(onboardingComplete)")
        }
    }
}

// MARK: - 5-screen Walkthrough

struct AppWalkthroughView: View {
    var onSkip: () -> Void
    var onFinish: () -> Void

    @State private var page = 0

    private let pages: [WalkPage] = [
        // 1. Welcome to Rep – Our Purpose-Driven Movement
        .init(
            title: "Welcome to Rep – our Purpose-Driven movement.",
            subtitle: "Rep helps you champion your priorities—\n\nlike a world-class sales rep. Let's accelerate.",
            imageSystem: nil,
            imageAssetName: "REPLogo",
            footnote: nil,
            ctaOverride: "Rep Something.",
            demo: nil
        ),
        // 2. Navigate Between Purposes and People
        .init(
            title: "flip between Purposes and People",
            subtitle: "tap the Rep logo in the bottom-right to toggle between active campaigns and the People driving them.",
            imageSystem: nil,
            imageAssetName: nil,
            ctaOverride: nil,
            demo: .toggleDemo,
            screenshotPortalsName: "MainScreen_Portals",
            screenshotPeopleName: "MainScreen_People"
        ),
        // 3. View Purpose Pitches in Full Screen
        .init(
            title: "view Purpose Pitches in full screen",
            subtitle: "tap the top image to open the Purpose Pitch, then swipe through in fullscreen.",
            imageSystem: nil,
            imageAssetName: nil,
            ctaOverride: nil,
            demo: .pitchDeckDemo,
            purposePageScreenshotName: "Purpose_page",
            fullscreenPitchScreenshotName: "Fullscreen_pitch"
        ),
        // 4. Join a Team. Accelerate the Mission.
        .init(
            title: "join a Goal Team. Accelerate the Mission.",
            subtitle: "view a Goal. join a Team. Accelerate your cause. and your career.",
            imageSystem: nil,
            imageAssetName: nil,
            ctaOverride: nil,
            demo: .joinTeamDemo,
            // Add screenshot paths for 3-step flow
            purposePageForGoalScreenshotName: "Purpose_page",
            goalDetailScreenshotName: "Goals_detail",
            actionMenuScreenshotName: "Action_menu"
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Skip") { onSkip() }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("About Rep").font(.headline)
                Spacer()
                Color.clear.frame(width: 44, height: 44)
            }
            .padding(.horizontal, 16)
            .frame(height: 44)

            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { idx in
                    WalkthroughPageView(page: pages[idx]).tag(idx)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))

            HStack(spacing: 12) {
                if page > 0 {
                    Button("Back") {
                        withAnimation { page -= 1 }
                    }
                    .frame(height: 48)
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                } else {
                    Color.clear.frame(height: 48).frame(maxWidth: .infinity)
                }

                let cta = pages[page].ctaOverride ?? (page == pages.count - 1 ? "Finish" : "Next")
                Button(cta) {
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        onFinish()
                    }
                }
                .frame(height: 48)
                .frame(maxWidth: .infinity)
                .background(Color.repGreen)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(16)
        }
        .background(Color.white.ignoresSafeArea())
    }
}

struct WalkPage: Hashable {
    enum Demo: Hashable {
        case toggleDemo
        case pitchDeckDemo
        case joinTeamDemo
    }
    
    let title: String
    let subtitle: String
    let imageSystem: String?
    let imageAssetName: String?
    let footnote: String?
    let ctaOverride: String?
    let demo: Demo?
    // Screen 2 screenshots
    let screenshotPortalsName: String?
    let screenshotPeopleName: String?
    // Screen 3 screenshots
    let purposePageScreenshotName: String?
    let fullscreenPitchScreenshotName: String?
    // Screen 4 screenshots
    let purposePageForGoalScreenshotName: String?
    let goalDetailScreenshotName: String?
    let actionMenuScreenshotName: String?
    
    init(
        title: String,
        subtitle: String,
        imageSystem: String? = nil,
        imageAssetName: String? = nil,
        footnote: String? = nil,
        ctaOverride: String? = nil,
        demo: Demo? = nil,
        screenshotPortalsName: String? = nil,
        screenshotPeopleName: String? = nil,
        purposePageScreenshotName: String? = nil,
        fullscreenPitchScreenshotName: String? = nil,
        purposePageForGoalScreenshotName: String? = nil,
        goalDetailScreenshotName: String? = nil,
        actionMenuScreenshotName: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.imageSystem = imageSystem
        self.imageAssetName = imageAssetName
        self.footnote = footnote
        self.ctaOverride = ctaOverride
        self.demo = demo
        self.screenshotPortalsName = screenshotPortalsName
        self.screenshotPeopleName = screenshotPeopleName
        self.purposePageScreenshotName = purposePageScreenshotName
        self.fullscreenPitchScreenshotName = fullscreenPitchScreenshotName
        self.purposePageForGoalScreenshotName = purposePageForGoalScreenshotName
        self.goalDetailScreenshotName = goalDetailScreenshotName
        self.actionMenuScreenshotName = actionMenuScreenshotName
    }
}

struct WalkthroughPageView: View {
    let page: WalkPage
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            // Prefer custom demo, then asset image, then SF Symbol
            if let demo = page.demo {
                switch demo {
                case .toggleDemo:
                    if let portals = page.screenshotPortalsName,
                       let people = page.screenshotPeopleName {
                        ToggleScreenshotDemoView(portalsImageName: portals, peopleImageName: people)
                            .padding(.bottom, 8)
                    } else {
                        ToggleDemoView()
                            .padding(.bottom, 8)
                    }
                case .pitchDeckDemo:
                    if let p = page.purposePageScreenshotName,
                       let f = page.fullscreenPitchScreenshotName {
                        PitchScreenshotsDemoView(purposeImageName: p, fullscreenImageName: f)
                            .padding(.bottom, 8)
                    } else {
                        PurposePitchDemoView()
                            .padding(.bottom, 8)
                    }
                case .joinTeamDemo:
                    if let p = page.purposePageForGoalScreenshotName,
                    let g = page.goalDetailScreenshotName,
                    let a = page.actionMenuScreenshotName {
                        JoinTeamScreenshotsDemoView(
                            purposePageImageName: p,
                            goalDetailImageName: g,
                            actionMenuImageName: a
                        )
                        .padding(.bottom, 8)
                    } else {
                        JoinTeamDemoView()
                            .padding(.bottom, 8)
                    }
                }
            } else if let asset = page.imageAssetName {
                Image(asset)
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .padding(.bottom, 8)
            } else if let sys = page.imageSystem {
                Image(systemName: sys)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .foregroundColor(Color.repGreen)
                    .padding(.bottom, 8)
            }

            Text(page.title)
                .font(.title)
                .fontWeight(.heavy)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Text(page.subtitle)
                .font(.title2)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            if let foot = page.footnote, !foot.isEmpty {
                Text(foot)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            Spacer()
        }
        .background(Color.white)
    }
}

// MARK: - Toggle Screenshot Demo (Screen 2)
// Shows real app screenshots with REP logo highlight
private struct ToggleScreenshotDemoView: View {
    let portalsImageName: String
    let peopleImageName: String

    @State private var showPortals = true
    @State private var pulseLogo = false
    @State private var timerStarted = false
    @State private var timerCancellable: AnyCancellable?

    // Card sizing tuned for portrait screenshots in onboarding
    private let maxCardWidth: CGFloat = 320
    private let maxCardHeight: CGFloat = 360
    private let cornerRadius: CGFloat = 16

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Cross-fade screenshots — scaledToFit to avoid cropping
            ZStack {
                Image(portalsImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: maxCardWidth, maxHeight: maxCardHeight, alignment: .center)
                    .opacity(showPortals ? 1 : 0)
                    .animation(.easeInOut(duration: 0.35), value: showPortals)

                Image(peopleImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: maxCardWidth, maxHeight: maxCardHeight, alignment: .center)
                    .opacity(showPortals ? 0 : 1)
                    .animation(.easeInOut(duration: 0.35), value: showPortals)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)

            // Pulsing highlight over the bottom-right (Rep logo button on screenshot)
            ZStack {
                Circle()
                    .fill(Color.repGreen.opacity(0.22))
                    .frame(width: 58, height: 58)
                    .scaleEffect(pulseLogo ? 1.1 : 0.92)

                Circle()
                    .stroke(Color.repGreen, lineWidth: 2.5)
                    .frame(width: 50, height: 50)
                    .scaleEffect(pulseLogo ? 1.15 : 1.0)
            }
            .animation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulseLogo)
            // These paddings align the ring over the on-screen Rep logo in your screenshots.
            // Tweak if needed to match your exact capture.
            .padding(.trailing, 70)
            .padding(.bottom, 1)
            .allowsHitTesting(false)
        }
        // Constrain the container so layout above/below text remains tidy
        .frame(maxWidth: maxCardWidth, maxHeight: maxCardHeight)
        .onAppear {
            startTimerIfNeeded()
        }
        .onDisappear {
            timerCancellable?.cancel()
            timerCancellable = nil
        }
        .onReceive(Timer.publish(every: 1.8, on: .main, in: .common).autoconnect()) { _ in
            withAnimation { showPortals.toggle() }
            withAnimation { pulseLogo = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation { pulseLogo = false }
            }
        }
    }

    private func startTimerIfNeeded() {
        guard !timerStarted else { return }
        timerStarted = true
        withAnimation { pulseLogo = true } // start pulsing immediately
    }
}

// MARK: - Join Team Demo (Screen 4)
// Shows a user joining a goal team and seeing progress update + team chat
private struct JoinTeamDemoView: View {
    // Animation states
    @State private var stage = 0 // 0: Browse teams, 1: Goal detail, 2: Joined (progress update), 3: Team chat
    @State private var joinButtonTapped = false
    @State private var progressValue: CGFloat = 0.3
    @State private var timerStarted = false
    @State private var showTapHint = false
    @State private var showChatTyping = false
    @State private var showChatBubble = false
    
    var body: some View {
        ZStack {
            switch stage {
            case 0:
                // Browse teams view
                browseTeamsView
                    .transition(.opacity)
            case 1:
                // Goal detail view
                goalDetailView
                    .transition(.opacity)
            case 2:
                // Progress update view
                progressUpdateView
                    .transition(.opacity)
            case 3:
                // Team chat view
                teamChatView
                    .transition(.opacity)
            default:
                EmptyView()
            }
        }
        .frame(width: 280, height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
        .onAppear {
            startTimerIfNeeded()
        }
        .onDisappear {
            timerCancellable?.cancel()
            timerCancellable = nil
        }
        .onReceive(timerPublisher) { _ in
            advanceAnimation()
        }
    }
    
    // Stage 1: Browse Teams View
    private var browseTeamsView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Goal Teams")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white)
            
            // List of teams
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(0..<3) { i in
                        teamListItem(
                            title: teamNames[i],
                            progress: teamProgress[i],
                            isHighlighted: i == 0
                        )
                        .onTapGesture {
                            if i == 0 {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    stage = 1
                                }
                            }
                        }
                    }
                }
                .padding(12)
            }
            .background(Color(UIColor.systemGray6))
            
            // "Tap first team" hint
            if showTapHint {
                VStack {
                    Text("Tap to view")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 32)
                .offset(y: -120)
                .transition(.opacity)
            }
        }
    }
    
    // Helper for team list items
    private func teamListItem(title: String, progress: CGFloat, isHighlighted: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Text("Recruiting")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            // Progress bar
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color(UIColor.systemGray5))
                    .frame(height: 12)
                Rectangle()
                    .fill(Color.repGreen)
                    .frame(width: 260 * progress, height: 12)
            }
            .cornerRadius(4)
            
            HStack {
                Text("Progress: \(Int(progress * 100))%")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(12)
        .background(isHighlighted && showTapHint ? Color.repGreen.opacity(0.1) : Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isHighlighted && showTapHint ? Color.repGreen : Color.clear, lineWidth: 1.5)
        )
    }
    
    // Stage 2: Goal Detail View
    private var goalDetailView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "chevron.left")
                    .foregroundColor(Color.repGreen)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Text("Climate Action")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                Color.clear.frame(width: 16)
            }
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(Color.white)
            
            // Progress bar
            VStack(alignment: .leading, spacing: 6) {
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(UIColor.systemGray5))
                        .frame(height: 20)
                    Rectangle()
                        .fill(Color.repGreen)
                        .frame(width: 260 * 0.3, height: 20)
                }
                .cornerRadius(4)
                
                HStack {
                    Text("Recruiting")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("30% Complete")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white)
            
            // Description
            Text("Join our team to help fight climate change through community action and advocacy.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            // Join button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    joinButtonTapped = true
                    stage = 2
                }
            }) {
                Text("Join Team")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 200, height: 32)
                    .background(Color.repGreen)
                    .cornerRadius(6)
                    .padding(.vertical, 8)
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(showTapHint ? 1.05 : 1.0)
            .brightness(showTapHint ? 0.1 : 0)
            .animation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: showTapHint)
        }
        .background(Color.white)
    }
    
    // Stage 3: Progress Update View (after join)
    private var progressUpdateView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "chevron.left")
                    .foregroundColor(Color.repGreen)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Text("Climate Action")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                Color.clear.frame(width: 16)
            }
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(Color.white)
            
            // Progress bar (animated)
            VStack(alignment: .leading, spacing: 6) {
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(UIColor.systemGray5))
                        .frame(height: 20)
                    Rectangle()
                        .fill(Color.repGreen)
                        .frame(width: 260 * progressValue, height: 20)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progressValue)
                }
                .cornerRadius(4)
                
                HStack {
                    Text("Recruiting")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(progressValue * 100))% Complete")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white)
            
            // Description with success message
            VStack(alignment: .leading, spacing: 8) {
                Text("Congratulations! You've joined the team!")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.repGreen)
                
                Text("Join our team to help fight climate change through community action and advocacy.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            // Team chat button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    stage = 3
                }
            }) {
                HStack {
                    Image(systemName: "bubble.left.fill")
                        .foregroundColor(.white)
                    Text("Team Chat")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 200, height: 32)
                .background(Color.repGreen)
                .cornerRadius(6)
                .padding(.vertical, 8)
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(showTapHint ? 1.05 : 1.0)
            .brightness(showTapHint ? 0.1 : 0)
            .animation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: showTapHint)
        }
        .background(Color.white)
    }
    
    // Stage 4: Team Chat View
    private var teamChatView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "chevron.left")
                    .foregroundColor(Color.repGreen)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Text("Climate Action Team")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                Color.clear.frame(width: 16)
            }
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(Color.white)
            
            // Member avatars
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(0..<4) { _ in
                        VStack {
                            Circle()
                                .fill(Color(UIColor.systemGray4))
                                .frame(width: 32, height: 32)
                            Text("RP")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            
            // Chat messages
            VStack(spacing: 10) {
                // Welcome message
                HStack(alignment: .top) {
                    Circle()
                        .fill(Color(UIColor.systemGray4))
                        .frame(width: 28, height: 28)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Team Lead")
                            .font(.system(size: 12, weight: .semibold))
                        
                        Text("Welcome to the Climate Action team! We're excited to have you join us.")
                            .font(.system(size: 12))
                            .padding(8)
                            .background(Color(UIColor.systemGray5))
                            .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                
                // Typing indicator / New message
                if showChatTyping {
                    HStack {
                        Circle()
                            .fill(Color(UIColor.systemGray4))
                            .frame(width: 28, height: 28)
                        
                        if !showChatBubble {
                            Text("Team Lead is typing...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 4)
                        } else {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Team Lead")
                                    .font(.system(size: 12, weight: .semibold))
                                
                                Text("Our next team meeting is Thursday at 6PM. Can you make it?")
                                    .font(.system(size: 12))
                                    .padding(8)
                                    .background(Color(UIColor.systemGray5))
                                    .cornerRadius(12)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .animation(.easeInOut, value: showChatBubble)
                }
                
                Spacer()
            }
            
            // Message input
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemGray6))
                    .frame(height: 36)
                    .overlay(
                        HStack {
                            Text("Type a message...")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .padding(.leading, 12)
                            Spacer()
                        }
                    )
                
                Circle()
                    .fill(Color.repGreen)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "arrow.up")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .semibold))
                    )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white)
        }
        .background(Color.white)
    }
    
    // Sample team data
    private let teamNames = ["Climate Action", "Education Access", "Food Security"]
    private let teamProgress: [CGFloat] = [0.3, 0.65, 0.47]
    
    // MARK: Timer and Animation Control
    @State private var timerCancellable: AnyCancellable?
    private var timerPublisher: Timer.TimerPublisher {
        Timer.publish(every: 2.2, on: .main, in: .common)
    }
    
    private func startTimerIfNeeded() {
        guard !timerStarted else { return }
        timerStarted = true
        
        // Start showing tap hint after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation { showTapHint = true }
        }
        
        timerCancellable = timerPublisher.autoconnect().sink { _ in /* handled in onReceive */ }
    }
    
    private func advanceAnimation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch stage {
            case 0:
                // Browse teams -> Goal detail
                stage = 1
            case 1:
                // Goal detail -> Progress update (after join)
                joinButtonTapped = true
                stage = 2
                // Animate progress bar filling
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    progressValue = 0.4
                }
            case 2:
                // Progress update -> Team chat
                stage = 3
                // Show typing indicator after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation { showChatTyping = true }
                }
                // Show message bubble after typing
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                    withAnimation { showChatBubble = true }
                }
            case 3:
                // Reset to start
                stage = 0
                joinButtonTapped = false
                progressValue = 0.3
                showChatTyping = false
                showChatBubble = false
            default:
                break
            }
        }
    }
}

// MARK: - Toggle Demo (Screen 2)
// Shows a subtle auto-playing toggle between Portals and People with a fake phone frame
private struct ToggleDemoView: View {
    @State private var showPortals = true
    @State private var pulseLogo = false
    @State private var timerStarted = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
                .frame(width: 280, height: 180)

            ZStack {
                // Portals grid preview
                if showPortals {
                    PortalsPreview()
                        .transition(.opacity)
                } else {
                    PeoplePreview()
                        .transition(.opacity)
                }
            }
            .frame(width: 244, height: 128)
            .animation(.easeInOut(duration: 0.35), value: showPortals)

            // REP logo button (bottom-right), pulsing on toggle
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image("REPLogo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 32, height: 32)
                        .scaleEffect(pulseLogo ? 1.08 : 1.0)
                        .animation(.easeInOut(duration: 0.25), value: pulseLogo)
                        .padding(.trailing, 10)
                        .padding(.bottom, 10)
                }
            }
            .frame(width: 280, height: 180)
        }
        .onAppear {
            startTimerIfNeeded()
        }
        .onDisappear {
            timerCancellable?.cancel()
            timerCancellable = nil
        }
        .onReceive(timerPublisher) { _ in
            withAnimation {
                showPortals.toggle()
                pulseLogo = true
            }
            // Reset pulse a bit after
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation { pulseLogo = false }
            }
        }
    }

    // MARK: Timer
    @State private var timerCancellable: AnyCancellable?
    private var timerPublisher: Timer.TimerPublisher {
        Timer.publish(every: 1.6, on: .main, in: .common)
    }
    private func startTimerIfNeeded() {
        guard !timerStarted else { return }
        timerStarted = true
        timerCancellable = timerPublisher.autoconnect().sink { _ in /* handled by onReceive above */ }
    }
}

private struct PortalsPreview: View {
    var body: some View {
        let cols = [GridItem(.flexible()), GridItem(.flexible())]
        LazyVGrid(columns: cols, spacing: 8) {
            ForEach(0..<4) { i in
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(i % 2 == 0 ? Color.repGreen.opacity(0.18) : Color(UIColor.systemGray6))
                    .overlay(
                        VStack(alignment: .leading, spacing: 4) {
                            RoundedRectangle(cornerRadius: 3).fill(Color.black.opacity(0.15)).frame(height: 8)
                            RoundedRectangle(cornerRadius: 3).fill(Color.black.opacity(0.08)).frame(height: 6)
                            Spacer()
                        }
                        .padding(8)
                    )
                    .frame(height: 56)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 4)
    }
}

private struct PeoplePreview: View {
    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<3) { _ in
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(UIColor.systemGray5))
                        .frame(width: 28, height: 28)
                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 3).fill(Color.black.opacity(0.15)).frame(width: 120, height: 8)
                        RoundedRectangle(cornerRadius: 3).fill(Color.black.opacity(0.08)).frame(width: 160, height: 6)
                    }
                    Spacer()
                }
                .padding(.horizontal, 8)
                .frame(height: 36)
                .background(Color.white)
                .overlay(
                    Rectangle()
                        .fill(Color(UIColor.systemGray5))
                        .frame(height: 1),
                    alignment: .bottom
                )
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Pitch screenshots demo (Screen 3)
// Portrait purpose page screenshot with pulsing tap hint on the top image → cross-fades to landscape fullscreen screenshot
private struct PitchScreenshotsDemoView: View {
    let purposeImageName: String
    let fullscreenImageName: String

    @State private var showPurpose = true
    @State private var pulse = false
    @State private var timerStarted = false
    @State private var timerCancellable: AnyCancellable?

    // Match screen 2 sizing
    private let maxCardWidth: CGFloat = 320
    private let maxCardHeight: CGFloat = 360
    private let cornerRadius: CGFloat = 16

    // Adjust to align dot over the hero/top image area on your Purpose_page screenshot
    private let dotYOffset: CGFloat = 78
    private let dotSize: CGFloat = 44

    var body: some View {
        ZStack {
            // Second (landscape) — hidden initially
            Image(fullscreenImageName)
                .resizable()
                .scaledToFit()
                .opacity(showPurpose ? 0 : 1)
                .animation(.easeInOut(duration: 0.35), value: showPurpose)

            // First (portrait) — visible initially
            Image(purposeImageName)
                .resizable()
                .scaledToFit()
                .opacity(showPurpose ? 1 : 0)
                .animation(.easeInOut(duration: 0.35), value: showPurpose)

            // Tap hint appears only on portrait
            if showPurpose {
                ZStack {
                    // Outer soft circle
                    Circle()
                        .fill(Color.repGreen.opacity(0.22))
                        .frame(width: dotSize * 1.32, height: dotSize * 1.32)
                        .scaleEffect(pulse ? 1.1 : 0.92)

                    // Inner stroked circle
                    Circle()
                        .stroke(Color.repGreen, lineWidth: 2.5)
                        .frame(width: dotSize, height: dotSize)
                        .scaleEffect(pulse ? 1.15 : 1.0)
                }
                .padding(.bottom, 0)
                .animation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulse)
                .offset(y: -maxCardHeight/2 + dotYOffset)
            }
        }
        .frame(maxWidth: maxCardWidth, maxHeight: maxCardHeight)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
        .onAppear {
            resetSequence()
            withAnimation { pulse = true } // Start pulsing immediately, like screen 2
        }
        .onDisappear {
            timerCancellable?.cancel()
            timerCancellable = nil
            timerStarted = false
            pulse = false
        }
        .onChange(of: purposeImageName) { _ in resetSequence() }
        .onChange(of: fullscreenImageName) { _ in resetSequence() }
    }

    private func resetSequence() {
        timerCancellable?.cancel()
        timerCancellable = nil
        timerStarted = false
        showPurpose = true
        startTimerIfNeeded()
        withAnimation { pulse = true } // Ensure pulse restarts on asset change
    }

    private func startTimerIfNeeded() {
        guard !timerStarted else { return }
        timerStarted = true
        let publisher = Timer.publish(every: 2.2, on: .main, in: .common)
        timerCancellable = publisher.autoconnect().sink { _ in
            withAnimation(.easeInOut(duration: 0.4)) {
                showPurpose.toggle()
            }
        }
    }
}
// MARK: - Join Team Screenshots Demo (Screen 4)
// Purpose_page → Goals_detail → Action_menu, with the same pulsing "click" ring
private struct JoinTeamScreenshotsDemoView: View {
    let purposePageImageName: String
    let goalDetailImageName: String
    let actionMenuImageName: String

    @State private var stage = 0 // 0: purpose page, 1: goal detail, 2: action menu
    @State private var pulse = false
    @State private var timerStarted = false
    @State private var timerCancellable: AnyCancellable?

    // Match sizing with other screenshot demos
    private let maxCardWidth: CGFloat = 320
    private let maxCardHeight: CGFloat = 360
    private let cornerRadius: CGFloat = 16

    // Ring size and positioning (adjust to match your screenshots)
    private let dotSize: CGFloat = 44
    
    // Tap on a Goal tile in Purpose page (from top-left)
    private let purposeTapYFromTop: CGFloat = 170
    private let purposeTapXFromLeft: CGFloat = 140

    // Tap on bottom action button in Goal detail (from bottom)
    private let goalDetailTapYFromBottom: CGFloat = 30
    private let goalDetailTapXCenterOffset: CGFloat = -10

    // Tap on "Join Team" option in action sheet (from bottom)
    private let actionMenuTapYFromBottom: CGFloat = 155
    private let actionMenuTapXCenterOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Cross-fade among three screenshots
            Image(purposePageImageName)
                .resizable()
                .scaledToFit()
                .opacity(stage == 0 ? 1 : 0)
                .animation(.easeInOut(duration: 0.35), value: stage)

            Image(goalDetailImageName)
                .resizable()
                .scaledToFit()
                .opacity(stage == 1 ? 1 : 0)
                .animation(.easeInOut(duration: 0.35), value: stage)

            Image(actionMenuImageName)
                .resizable()
                .scaledToFit()
                .opacity(stage == 2 ? 1 : 0)
                .animation(.easeInOut(duration: 0.35), value: stage)

            // Pulsing "click" ring
            ZStack {
                Circle()
                    .fill(Color.repGreen.opacity(0.22))
                    .frame(width: dotSize * 1.32, height: dotSize * 1.32)
                    .scaleEffect(pulse ? 1.1 : 0.92)

                Circle()
                    .stroke(Color.repGreen, lineWidth: 2.5)
                    .frame(width: dotSize, height: dotSize)
                    .scaleEffect(pulse ? 1.15 : 1.0)
            }
            .animation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulse)
            .offset(clickOffset(for: stage))
            .allowsHitTesting(false)
        }
        .frame(maxWidth: maxCardWidth, maxHeight: maxCardHeight)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
        .onAppear {
            startLoop()
        }
        .onDisappear {
            timerCancellable?.cancel()
            timerCancellable = nil
            timerStarted = false
            pulse = false
        }
    }

    private func startLoop() {
        guard !timerStarted else { return }
        timerStarted = true
        withAnimation { pulse = true }

        let publisher = Timer.publish(every: 2.2, on: .main, in: .common)
        timerCancellable = publisher.autoconnect().sink { _ in
            withAnimation(.easeInOut(duration: 0.4)) {
                stage = (stage + 1) % 3
            }
        }
    }

    private func clickOffset(for stage: Int) -> CGSize {
        switch stage {
        case 0:
            // Position on Goal tile in Purpose page
            return CGSize(
                width: -maxCardWidth/2 + purposeTapXFromLeft,
                height: -maxCardHeight/2 + purposeTapYFromTop
            )
        case 1:
            // Position on bottom action button in Goal detail
            return CGSize(
                width: goalDetailTapXCenterOffset,
                height: maxCardHeight/2 - goalDetailTapYFromBottom
            )
        default:
            // Position on "Join Team" in action sheet
            return CGSize(
                width: actionMenuTapXCenterOffset,
                height: maxCardHeight/2 - actionMenuTapYFromBottom
            )
        }
    }
}

// MARK: - Purpose Pitch Demo (legacy, used as fallback when screenshots not provided)
// Shows an animated flow: MainScreen → Purpose Page → Fullscreen Pitch
private struct PurposePitchDemoView: View {
    // Animation states
    @State private var showingStage = 0
    @State private var isExpanding = false
    @State private var isFullscreen = false
    @State private var timerStarted = false
    @State private var activePitchSlide = 0
    @State private var showTapHint = false
    
    var body: some View {
        ZStack {
            if showingStage == 0 {
                // STAGE 1: Portal grid (MainScreen-like)
                portalGridView
                    .transition(.opacity)
            } else if showingStage == 1 {
                // STAGE 2: Portal detail page
                portalDetailView
                    .transition(.opacity)
            } else {
                // STAGE 3: Fullscreen pitch
                fullscreenPitchView
                    .transition(.opacity)
            }
        }
        .frame(width: 280, height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
        .onAppear {
            startTimerIfNeeded()
        }
        .onDisappear {
            timerCancellable?.cancel()
            timerCancellable = nil
        }
        .onReceive(timerPublisher) { _ in
            advanceAnimation()
        }
    }
    
    // STAGE 1: Portal Grid (MainScreen-like)
    private var portalGridView: some View {
        VStack(spacing: 0) {
            // Nav bar
            HStack {
                Circle()
                    .fill(Color(UIColor.systemGray5))
                    .frame(width: 22, height: 22)
                Spacer()
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black)
                    .frame(width: 80, height: 22)
                Spacer()
                Circle()
                    .fill(Color.repGreen)
                    .frame(width: 22, height: 22)
            }
            .padding(.horizontal, 16)
            .frame(height: 40)
            .background(Color.white)
            
            // Grid of portals
            let columns = [GridItem(.flexible()), GridItem(.flexible())]
            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(0..<4) { i in
                        portalGridItem(isHighlighted: i == 0)
                            .onTapGesture {
                                if i == 0 {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showingStage = 1
                                    }
                                }
                            }
                    }
                }
                .padding(8)
            }
            .background(Color(UIColor.systemGray6))
            
            // "Tap first portal" hint
            if showTapHint {
                VStack {
                    Text("Tap to view")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 32)
                .offset(y: -60)
                .transition(.opacity)
            }
        }
    }
    
    private func portalGridItem(isHighlighted: Bool) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(isHighlighted ? Color.repGreen.opacity(0.15) : Color(UIColor.systemBackground))
            .overlay(
                VStack(alignment: .leading, spacing: 4) {
                    // Title bar
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.black.opacity(0.7))
                        .frame(height: 12)
                        .frame(width: 80)
                    
                    // Subtitle
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.black.opacity(0.4))
                        .frame(height: 8)
                        .frame(width: 100)
                    
                    Spacer()
                    
                    if isHighlighted {
                        // Pulse effect on the highlighted portal
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.repGreen)
                            .frame(height: 24)
                            .frame(maxWidth: .infinity)
                            .opacity(showTapHint ? 0.9 : 0.6)
                            .animation(Animation.easeInOut(duration: 0.8).repeatForever(), value: showTapHint)
                    }
                }
                .padding(12)
            )
            .frame(height: 120)
    }
    
    // STAGE 2: Portal Detail View
    private var portalDetailView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "chevron.left")
                    .foregroundColor(Color.repGreen)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Text("Purpose")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                Color.clear.frame(width: 16)
            }
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(Color.white)
            
            // Main image preview (tappable to go fullscreen)
            Rectangle()
                .fill(Color.repGreen.opacity(0.2))
                .overlay(
                    VStack {
                        Image(systemName: "rectangle.on.rectangle")
                            .font(.system(size: 32))
                            .foregroundColor(.repGreen)
                            .opacity(showTapHint ? 1.0 : 0.7)
                            .scaleEffect(showTapHint ? 1.1 : 1.0)
                            .animation(Animation.easeInOut(duration: 0.8).repeatForever(), value: showTapHint)
                        
                        Text("Tap to view fullscreen")
                            .font(.caption)
                            .foregroundColor(.black)
                            .padding(.top, 4)
                    }
                )
                .frame(height: 90)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingStage = 2
                    }
                }
            
            // Content tabs
            HStack {
                Text("Goal Teams")
                    .font(.caption)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(Color.white)
                    .foregroundColor(.black)
                
                Text("Story")
                    .font(.caption)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(Color.black)
                    .foregroundColor(.white)
            }
            .frame(height: 28)
            .background(Color.white)
            
            // Content preview
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.black.opacity(0.7))
                        .frame(height: 10)
                        .frame(width: 140)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.black.opacity(0.4))
                        .frame(height: 8)
                        .frame(maxWidth: .infinity)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.black.opacity(0.4))
                        .frame(height: 8)
                        .frame(maxWidth: .infinity)
                }
                .padding(12)
            }
            .background(Color.white)
        }
    }
    
    // STAGE 3: Fullscreen Pitch View
    private var fullscreenPitchView: some View {
        ZStack {
            // Landscape orientation container
            HStack(spacing: 0) {
                // Current slide content
                if activePitchSlide == 0 {
                    // Slide 1: Mission
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mission")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                        
                        Text("Change the world with us")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Rectangle()
                            .fill(Color.repGreen)
                            .frame(height: 24)
                            .cornerRadius(4)
                            .overlay(
                                Text("Swipe →")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            )
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
                } else if activePitchSlide == 1 {
                    // Slide 2: Impact
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Impact")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                        
                        HStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.repGreen.opacity(0.2))
                                .overlay(
                                    Image(systemName: "chart.bar.fill")
                                        .foregroundColor(.repGreen)
                                )
                                .frame(width: 40, height: 40)
                            
                            VStack(alignment: .leading) {
                                Text("200+")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Participants")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Rectangle()
                            .fill(Color.repGreen)
                            .frame(height: 24)
                            .cornerRadius(4)
                            .overlay(
                                Text("Swipe →")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            )
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
                } else {
                    // Slide 3: Take Action
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Take Action")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        VStack(spacing: 8) {
                            Rectangle()
                                .fill(Color.repGreen)
                                .frame(height: 32)
                                .cornerRadius(6)
                                .overlay(
                                    Text("Join Goal Team")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                )
                            
                            Rectangle()
                                .stroke(Color.repGreen, lineWidth: 2)
                                .frame(height: 32)
                                .cornerRadius(6)
                                .overlay(
                                    Text("Message Lead Rep")
                                        .font(.system(size: 12))
                                        .foregroundColor(.repGreen)
                                )
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
                }
                
                // Dot indicators + Exit button
                VStack {
                    Spacer()
                    
                    // Dot indicators
                    VStack(spacing: 6) {
                        ForEach(0..<3) { i in
                            Circle()
                                .fill(activePitchSlide == i ? Color.repGreen : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(8)
                    
                    Spacer()
                    
                    // Exit button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingStage = 1
                        }
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.black)
                            .font(.system(size: 14, weight: .bold))
                            .padding(8)
                            .background(Circle().fill(Color.white.opacity(0.8)))
                    }
                    .padding(8)
                }
                .frame(width: 24)
                .background(Color.black.opacity(0.1))
            }
            // Overlay swipe gesture hint (only on first slide)
            .overlay(
                Group {
                    if activePitchSlide == 0 && showTapHint {
                        HStack {
                            Spacer()
                            Image(systemName: "arrow.right")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Circle().fill(Color.black.opacity(0.5)))
                                .offset(x: showTapHint ? 0 : 10)
                                .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: showTapHint)
                            Spacer()
                        }
                    }
                }
            )
        }
        .rotationEffect(.degrees(90))
        .frame(width: 180, height: 280)  // Swap dimensions for landscape effect
    }
    
    // MARK: Timer and Animation Control
    @State private var timerCancellable: AnyCancellable?
    private var timerPublisher: Timer.TimerPublisher {
        Timer.publish(every: 2.0, on: .main, in: .common)
    }
    
    private func startTimerIfNeeded() {
        guard !timerStarted else { return }
        timerStarted = true
        
        // Start showing tap hint after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation { showTapHint = true }
        }
        
        timerCancellable = timerPublisher.autoconnect().sink { _ in /* handled in onReceive */ }
    }
    
    private func advanceAnimation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if showingStage == 0 {
                // MainScreen -> Portal Page
                showingStage = 1
            } else if showingStage == 1 {
                // Portal Page -> Fullscreen
                showingStage = 2
            } else {
                // In fullscreen, advance slides
                if activePitchSlide < 2 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        activePitchSlide += 1
                    }
                } else {
                    // Reset to MainScreen to restart demo
                    activePitchSlide = 0
                    showingStage = 0
                }
            }
        }
    }
}
