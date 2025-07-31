import SwiftUI

struct TermsOfUseView: View {
    var onAccept: (() -> Void)? = nil // Optional closure for onboarding

    var body: some View {
        VStack(spacing: 24) {
            ScrollView {
                Text("""
                Terms of Use:  
                    Version: 1.1
                    Effective Date: 7/30/2025
                    App Name: Rep 1
                    Developer: Networked Capital Inc.

                    Welcome to Rep. By continuing, you agree to the following community guidelines and terms:
                    1. Community Standards
                    Users must not post objectionable, offensive, or abusive content.
                    Hate speech, harassment, and explicit material are strictly prohibited.
                    Violators may have their content removed and accounts suspended or banned.
                    2. User Responsibilities
                    You are solely responsible for the content you share, create, or promote.
                    Impersonation, deception, or targeted harassment is not tolerated.
                    3. Moderation & Enforcement
                    Rep reserves the right to monitor, moderate, and remove content at its discretion.
                    Inappropriate content can be flagged by users and reviewed by our team.
                    Users can block others to prevent unwanted or abusive interactions.
                    4. Agreement
                    By using Rep, you acknowledge and agree to uphold these standards.
                    Before proceeding, you must confirm acceptance of these terms.
                """)
                .padding()
            }
            if let onAccept = onAccept {
                Button("Accept Terms of Use") {
                    onAccept()
                }
                .font(.headline)
                .padding()
                .background(Color.repGreen)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .navigationTitle("Terms of Use")
        .navigationBarTitleDisplayMode(.inline)
    }
}
