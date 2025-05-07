import UIKit
import SwiftUI

class ViewController: UIViewController {

// MARK: - Properties
// Add your properties here

    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        // Additional setup after loading the view.
    }

    // MARK: - Custom Methods
    // Add your custom methods here
}

struct ProfileView: View {
    @State private var activeTab: String = "rep"

    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // Custom status bar
                StatusBarView()

                // Navigation header
                NavigationHeaderView()

                // Profile info
                ProfileInfoView()

                // Tab bar
                TabBarView(activeTab: $activeTab)

                // Content based on active tab
                ScrollView {
                    VStack(spacing: 0) {
                        if activeTab == "rep" {
                            ProfileContentView()
                        } else if activeTab == "goals" {
                            GoalsContentView()
                        } else if activeTab == "write" {
                            WriteContentView()
                        }
                    }
                    .padding(.bottom, 60) // Add padding for the bottom bar
                }

                Spacer()
            }

            // Fixed bottom bar
            BottomBarView()
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }
}

struct StatusBarView: View {
    var body: some View {
        HStack {
            Text("9:41")
                .font(.system(size: 14))
                .foregroundColor(.black)

            Spacer()

            // Battery, WiFi icons would go here in a real implementation
        }
        .frame(height: 48)
        .padding(.horizontal, 19)
        .background(Color(UIColor(red: 0.976, green: 0.976, blue: 0.976, alpha: 1.0)))
    }
}

struct NavigationHeaderView: View {
    var body: some View {
        HStack {
            Image(systemName: "chevron.down")
                .foregroundColor(Color(UIColor(red: 0.549, green: 0.78, blue: 0.365, alpha: 1.0)))
                .font(.system(size: 20))

            Spacer()

            Text("Jose Barrera")
                .font(.system(size: 20, weight: .bold))

            Spacer()

            // Empty view for symmetry
            Color.clear.frame(width: 24, height: 24)
        }
        .frame(height: 60)
        .padding(.horizontal, 15)
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(UIColor(red: 0.894, green: 0.894, blue: 0.894, alpha: 1.0))),
            alignment: .bottom
        )
    }
}

struct ProfileInfoView: View {
    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            // Profile image
            AsyncImage(url: URL(string: "https://cdn.builder.io/api/v1/image/assets/TEMP/87fbadb180eb8aacf43e8f44ba102e18fea11e27&format=webp")) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if phase.error != nil {
                    Color.gray
                } else {
                    Color.gray.opacity(0.3)
                }
            }
            .frame(width: 108, height: 108)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 7) {
                Text("Rep Type: Lead City: LA")
                    .font(.system(size: 17, weight: .bold))

                VStack(alignment: .leading, spacing: 4) {
                    Text("1. Human Resources - Scale")
                    Text("2. Operations - Manufacturing")
                    Text("3. Sales Social Connector")
                }
                .font(.system(size: 17))
                .lineSpacing(4)
            }
            .padding(.top, 5)

            Spacer()
        }
        .padding(15)
    }
}

struct TabBarView: View {
    @Binding var activeTab: String

    var body: some View {
        HStack(spacing: 0) {
            TabButton(title: "Rep", isActive: activeTab == "rep") {
                activeTab = "rep"
            }
            .overlay(
                Rectangle()
                    .frame(width: 1)
                    .foregroundColor(.black),
                alignment: .trailing
            )

            TabButton(title: "Goals", isActive: activeTab == "goals") {
                activeTab = "goals"
            }
            .overlay(
                Rectangle()
                    .frame(width: 1)
                    .foregroundColor(.black),
                alignment: .trailing
            )

            TabButton(title: "Write", isActive: activeTab == "write") {
                activeTab = "write"
            }
        }
        .frame(height: 34)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.black, lineWidth: 1)
        )
        .padding(.horizontal, 15)
    }
}

struct TabButton: View {
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: isActive ? .medium : .regular))
                .foregroundColor(isActive ? Color(UIColor(red: 0.482, green: 0.749, blue: 0.294, alpha: 1.0)) : .black)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.clear)
    }
}

struct ProfileContentView: View {
    var body: some View {
        VStack(spacing: 0) {
            ForEach(profileCards, id: \.title) { card in
                ProfileCardView(card: card)
            }
        }
        .padding(.horizontal, 15)
    }
}

struct GoalsContentView: View {
    var body: some View {
        VStack(alignment: .center) {
            Text("Goals Content")
                .font(.system(size: 17))
                .padding()
        }
    }
}

struct WriteContentView: View {
    var body: some View {
        VStack(alignment: .center) {
            Text("Write Content")
                .font(.system(size: 17))
                .padding()
        }
    }
}

struct BottomBarView: View {
    var body: some View {
        HStack(spacing: 30) {
            Button(action: {
                // Add new item action
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 291, height: 41)
                    .background(Color(UIColor(red: 0.482, green: 0.749, blue: 0.294, alpha: 1.0)))
                    .cornerRadius(6)
                    .shadow(color: Color(UIColor(red: 0.482, green: 0.749, blue: 0.294, alpha: 0.1)), radius: 3, x: 1, y: 4)
            }

            Button(action: {
                // Message action
            }) {
                Image(systemName: "message")
                    .font(.system(size: 20))
                    .foregroundColor(.black)
            }
        }
        .frame(height: 51)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(UIColor(red: 0.894, green: 0.894, blue: 0.894, alpha: 1.0))),
            alignment: .top
        )
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}

struct ProfileCard {
    let title: String
    let description: String
    let imageUrl: String
    let isCustomBackground: Bool
    let backgroundColor: Color?
    let customContent: AnyView?

    init(
        title: String,
        description: String,
        imageUrl: String,
        isCustomBackground: Bool = false,
        backgroundColor: Color? = nil,
        customContent: AnyView? = nil
    ) {
        self.title = title
        self.description = description
        self.imageUrl = imageUrl
        self.isCustomBackground = isCustomBackground
        self.backgroundColor = backgroundColor
        self.customContent = customContent
    }
}

struct ProfileCardView: View {
    let card: ProfileCard

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Card image or custom content
            if card.isCustomBackground && card.customContent != nil {
                card.customContent!
                    .frame(width: 178, height: 90)
            } else if card.isCustomBackground && card.backgroundColor != nil {
                card.backgroundColor!
                    .frame(width: 178, height: 90)
            } else {
                AsyncImage(url: URL(string: "\(card.imageUrl)&format=webp")) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .cover)
                    } else if phase.error != nil {
                        Color.gray
                    } else {
                        Color.gray.opacity(0.3)
                    }
                }
                .frame(width: 178, height: 90)
            }

            // Card content
            VStack(alignment: .leading, spacing: 4) {
                Text(card.title)
                    .font(.system(size: 17, weight: .bold))

                Text(card.description)
                    .font(.system(size: 17))
            }
            .padding(.top, 3)

            Spacer()
        }
        .padding(.vertical, 14)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(UIColor(red: 0.894, green: 0.894, blue: 0.894, alpha: 1.0))),
            alignment: .bottom
        )
    }
}

// Boys & Girls Club custom content
struct BGCLogoView: View {
    var body: some View {
        ZStack {
            Color(UIColor(red: 0, green: 0.576, blue: 0.816, alpha: 1.0))

            VStack(spacing: 1) {
                AsyncImage(url: URL(string: "https://cdn.builder.io/api/v1/image/assets/TEMP/d4a6a0d0ddb849dfe1884db98a4ec691983e1a16&format=webp")) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else if phase.error != nil {
                        Color.gray
                    } else {
                        Color.gray.opacity(0.3)
                    }
                }
                .frame(width: 131, height: 50)

                VStack(spacing: 0) {
                    Text("BOYS & GIRLS CLUBS")
                        .font(.custom("Alkalami", size: 12))
                        .foregroundColor(.white)

                    Text("OF THE SIOUX EMPIRE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
                .lineSpacing(1.2)
            }
            .frame(width: 131)
        }
    }
}

// Sample data for profile cards
let profileCards = [
    ProfileCard(
        title: "Economic Advancement",
        description: "Increasing my income by 50% in 2 years.",
        imageUrl: "https://cdn.builder.io/api/v1/image/assets/TEMP/2460fce7187bd62a3df0309aa8e16ea1c3c5db54"
    ),
    ProfileCard(
        title: "Boys & Girls Club",
        description: "4 volunteer hours per month",
        imageUrl: "https://cdn.builder.io/api/v1/image/assets/TEMP/d4a6a0d0ddb849dfe1884db98a4ec691983e1a16",
        isCustomBackground: true,
        backgroundColor: Color(UIColor(red: 0, green: 0.576, blue: 0.816, alpha: 1.0)),
        customContent: AnyView(BGCLogoView())
    ),
    ProfileCard(
        title: "Education",
        description: "16 hours of coding school per month",
        imageUrl: "https://cdn.builder.io/api/v1/image/assets/TEMP/f265c57b67c280fd401dba8430b0d38587d04450"
    ),
    ProfileCard(
        title: "EGT Solar",
        description: "Sourcing commercial solar leads",
        imageUrl: "https://cdn.builder.io/api/v1/image/assets/TEMP/68d3c97d890eeff370980bab2545ba73b2617eb7"
    ),
    ProfileCard(
        title: "Networked Capital",
        description: "Building Super-Intelligence together",
        imageUrl: "https://cdn.builder.io/api/v1/image/assets/TEMP/461e6c1c1c471394cd09dedd26d51cd4cd28f236"
    )
]

struct Profile {
    let name: String
    let imageUrl: String
    let repType: String
    let city: String
    let skills: [String]
    let cards: [ProfileCard]
}

// Sample profile data
let sampleProfile = Profile(
    name: "Jose Barrera",
    imageUrl: "https://cdn.builder.io/api/v1/image/assets/TEMP/87fbadb180eb8aacf43e8f44ba102e18fea11e27",
    repType: "Lead",
    city: "LA",
    skills: [
        "Human Resources - Scale",
        "Operations - Manufacturing",
        "Sales Social Connector"
    ],
    cards: profileCards
)