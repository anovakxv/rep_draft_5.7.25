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
import SwiftUI

struct MissionNCView: View {
    @State private var activeTab: String = "Story"
    @State private var activeSlide: Int = 0
    @State private var isFullScreen: Bool = false

    @State private var graphics: [String] = [
        "https://cdn.builder.io/api/v1/image/assets/TEMP/06a95f73d05bfcc82110cc68bcd20d051cd1d57dac200d36449bddeae10773f2",
        "https://cdn.builder.io/api/v1/image/assets/TEMP/additional-graphic-1",
        "https://cdn.builder.io/api/v1/image/assets/TEMP/additional-graphic-2"
    ]

    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("9:41")
                                .font(.system(size: 14, weight: .semibold))
                                .kerning(-0.28)
                                .padding(.leading, 17)

                            Image(systemName: "arrow.left")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .padding(.top, 25)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            HStack(spacing: 5) {
                                AsyncImage(url: URL(string: "https://cdn.builder.io/api/v1/image/assets/TEMP/e70e566cf1143a39a400aff9c8ebcb5d12d79198015444e0e5b556e354c5adf8?placeholderIfAbsent=true&apiKey=c8d530c75cd1478687ed622797fda84f&format=webp")) { image in
                                    image.resizable().aspectRatio(contentMode: .fit)
                                } placeholder: {
                                    Color.gray.opacity(0.3)
                                }
                                .frame(width: 15, height: 15)

                                AsyncImage(url: URL(string: "https://cdn.builder.io/api/v1/image/assets/TEMP/5e9d99f464ed265a4827f7db201ba880fc310248b3a07f96786c438ffae2a1ee?placeholderIfAbsent=true&apiKey=c8d530c75cd1478687ed622797fda84f&format=webp")) { image in
                                    image.resizable().aspectRatio(contentMode: .fit)
                                } placeholder: {
                                    Color.gray.opacity(0.3)
                                }
                                .frame(width: 15, height: 15)
                            }

                            Text("Networked Capital")
                                .font(.system(size: 20, weight: .semibold))
                                .position(x: UIScreen.main.bounds.width / 2 - 52, y: 31)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 15)
                    .padding(.trailing, 37)
                    .padding(.top, 13)
                    .background(Color(red: 0.98, green: 0.98, blue: 0.98))
                }

                ScrollView {
                    VStack(spacing: 0) {
                        // Image Carousel
                        CarouselView(
                            graphics: graphics,
                            activeSlide: $activeSlide,
                            isFullScreen: $isFullScreen
                        )

                        // Tab Selector
                        TabSelectorView(activeTab: $activeTab)
                            .padding(.top, 6)
                            .padding(.horizontal, 15)

                        Divider()
                            .frame(width: 400, height: 1)
                            .background(Color(red: 0.89, green: 0.89, blue: 0.89))
                            .padding(.top, 8)

                        // Team Members Section
                        VStack(spacing: 0) {
                            HStack(alignment: .top, spacing: 6) {
                                Spacer()

                                ProfileImageView(imageUrl: "https://cdn.builder.io/api/v1/image/assets/TEMP/36f52c418a1c0681b6c727d76ad4b2273527e944ecbdeb570c4ce5bc1f42300e?placeholderIfAbsent=true&apiKey=c8d530c75cd1478687ed622797fda84f")
                                ProfileImageView(imageUrl: "https://cdn.builder.io/api/v1/image/assets/TEMP/fb149407a98bc20b19ab0c6c864b9d185d44c32f42631bec48b21a06113a2bb4?placeholderIfAbsent=true&apiKey=c8d530c75cd1478687ed622797fda84f")
                                ProfileImageView(imageUrl: "https://cdn.builder.io/api/v1/image/assets/TEMP/61625b14180b7c1a9481eec18d60d211059a7981edaad1eef329cb99cf907c40?placeholderIfAbsent=true&apiKey=c8d530c75cd1478687ed622797fda84f")
                                ProfileImageView(imageUrl: "https://cdn.builder.io/api/v1/image/assets/TEMP/91a2e0c0bf79bb5ec1a6a992e510ce17cc2669e0937643909d9f717586402321?placeholderIfAbsent=true&apiKey=c8d530c75cd1478687ed622797fda84f")
                            }
                            .padding(.top, 16)

                            HStack(alignment: .center, spacing: 6) {
                                Text("Leads:")
                                    .font(.system(size: 18, weight: .semibold))

                                ProfileImageView(imageUrl: "https://cdn.builder.io/api/v1/image/assets/TEMP/68ae988fbe6c2e56903258b9e68721d8fddf60f30550c0affd824ca4a206684a?placeholderIfAbsent=true&apiKey=c8d530c75cd1478687ed622797fda84f")
                                ProfileImageView(imageUrl: "https://cdn.builder.io/api/v1/image/assets/TEMP/f29954bd6f06a9699865d3bad8e73ac6d8a83882a17c19c119bdfd185ebc75e5?placeholderIfAbsent=true&apiKey=c8d530c75cd1478687ed622797fda84f")
                                ProfileImageView(imageUrl: "https://cdn.builder.io/api/v1/image/assets/TEMP/d89fdda0735df03f699f3d7d3d14970a092592767525979bf8efd6dca9c8c071?placeholderIfAbsent=true&apiKey=c8d530c75cd1478687ed622797fda84f")
                                ProfileImageView(imageUrl: "https://cdn.builder.io/api/v1/image/assets/TEMP/3e205934b31a2efa12649ef6919f348ca15b4fdea9d4d2c5e55eb7688541e18c?placeholderIfAbsent=true&apiKey=c8d530c75cd1478687ed622797fda84f")
                                ProfileImageView(imageUrl: "https://cdn.builder.io/api/v1/image/assets/TEMP/3b02da8f80137814b70f65971fec46035ad10629e7160d94dd9bde85977b52e5?placeholderIfAbsent=true&apiKey=c8d530c75cd1478687ed622797fda84f")
                            }
                            .padding(.top, -32)
                            .padding(.horizontal, 15)

                            HStack(spacing: 17) {
                                Spacer()
                                Text("MP").font(.system(size: 14, weight: .semibold))
                                Text("CP").font(.system(size: 14, weight: .semibold))
                                Text("MN").font(.system(size: 14, weight: .semibold))
                            }
                            .padding(.horizontal, 15)

                            HStack(spacing: 18) {
                                Text("AN").font(.system(size: 14, weight: .semibold))
                                Text("HJ").font(.system(size: 14, weight: .semibold))
                                Text("AO").font(.system(size: 14, weight: .semibold))
                                Text("RH").font(.system(size: 14, weight: .semibold))
                                Text("KR").font(.system(size: 14, weight: .semibold))
                                Text("JB").font(.system(size: 14, weight: .semibold))
                            }
                            .padding(.top, -24)

                            // Content Section
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Networked Capital")
                                    .font(.system(size: 16, weight: .bold))
                                    + Text("\nis a coalition working together on shared principles.")
                                    .font(.system(size: 16))

                                Text("Our goal is to open source the next big company")
                                    .font(.system(size: 16, weight: .bold))
                                    + Text(" — to: innovate how we invest in People.")
                                    .font(.system(size: 16))

                                Text("Our Mission is to improve the health of human capital.")
                                    .font(.system(size: 16, weight: .bold))

                                Text("We do this by investing financial capital through a transparently articulated framework of timeless")
                                    .font(.system(size: 16))
                                + Text(" Principles")
                                    .font(.system(size: 16))
                                    .foregroundColor(.blue)
                                    .underline()
                                + Text(".")
                                    .font(.system(size: 16))

                                Text("We empower people to:")
                                    .font(.system(size: 16))

                                VStack(alignment: .leading, spacing: 5) {
                                    BulletPointView(text: "Maximize their strengths")
                                    BulletPointView(text: "Have access to resources and incentives")
                                    BulletPointView(text: "Increase the efficiency, agility, and quality of work")
                                }
                            }
                            .padding(.horizontal, 15)
                            .padding(.top, 13)
                            .padding(.bottom, 80)
                        }
                    }
                }

                Spacer()
            }

            // Bottom Navigation
            VStack {
                Spacer()
                BottomNavigationView()
            }
        }
        .frame(maxWidth: 480)
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct MissionNCView_Previews: PreviewProvider {
    static var previews: some View {
        MissionNCView()
    }
}
import SwiftUI

import SwiftUI

struct CarouselView: View {
    let graphics: [String]
    @Binding var activeSlide: Int
    @Binding var isFullScreen: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $activeSlide) {
                ForEach(0..<graphics.count, id: \.self) { index in
                    AsyncImage(url: URL(string: "\(graphics[index])&format=webp&placeholderIfAbsent=true&apiKey=c8d530c75cd1478687ed622797fda84f")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .gesture(
                                DragGesture()
                                    .onEnded { value in
                                        if value.translation.height < 0 {
                                            withAnimation {
                                                isFullScreen = false
                                                // In a real app, you would implement exiting fullscreen and orientation unlock here
                                                // UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                                            }
                                        }
                                    }
                            )
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .tag(index)
                    .onTapGesture {
                        withAnimation {
                            isFullScreen = true
                            // In a real app, you would implement fullscreen and orientation lock here
                            // UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
                        }
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 300)
            .background(Color.black.opacity(0.05))

            // Indicator dots
            HStack(spacing: 8) {
                ForEach(0..<graphics.count, id: \.self) { index in
                    Circle()
                        .fill(activeSlide == index ? Color.white : Color.white.opacity(0.5))
                        .frame(width: 8, height: 8)
                        .onTapGesture {
                            withAnimation {
                                activeSlide = index
                            }
                        }
                }
            }
            .padding(.bottom, 16)

            Divider()
                .frame(height: 1)
                .background(Color(red: 0.89, green: 0.89, blue: 0.89))
                .offset(y: 0.5)
        }
    }
}
import SwiftUI

struct TabSelectorView: View {
    @Binding var activeTab: String

    var body: some View {
        HStack(spacing: 0) {
            TabButton(title: "Story", isActive: activeTab == "Story") {
                activeTab = "Story"
            }
            .clipShape(RoundedRectangle(cornerRadius: 6).cornerRadius(6, corners: [.topLeft, .bottomLeft]))

            Divider()
                .frame(width: 1)
                .background(Color.black)

            TabButton(title: "Offering", isActive: activeTab == "Offering") {
                activeTab = "Offering"
            }

            Divider()
                .frame(width: 1)
                .background(Color.black)

            TabButton(title: "Results", isActive: activeTab == "Results") {
                activeTab = "Results"
            }
            .clipShape(RoundedRectangle(cornerRadius: 6).cornerRadius(6, corners: [.topRight, .bottomRight]))
        }
        .frame(maxWidth: 399)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.black, lineWidth: 1)
        )
    }
}

struct TabButton: View {
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(isActive ? .white : .black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isActive ? Color.black : Color.clear)
        }
    }
}

// Extension to apply corner radius to specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

struct RoundedCornerShape: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
import SwiftUI

struct ProfileImageView: View {
    let imageUrl: String

    var body: some View {
        AsyncImage(url: URL(string: "\(imageUrl)&format=webp")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Color.gray.opacity(0.3)
        }
        .frame(width: 32, height: 32)
        .clipShape(Circle())
    }
}
import SwiftUI

struct BulletPointView: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.system(size: 16))

            Text(text)
                .font(.system(size: 16))
        }
    }
}
import SwiftUI

struct BottomNavigationView: View {
    var body: some View {
        HStack(spacing: 0) {
            Spacer()

            Button(action: {
                // Action for green button
            }) {
                AsyncImage(url: URL(string: "https://cdn.builder.io/api/v1/image/assets/TEMP/69a4f889a47306008e33152e2aa960aea6feb5d34e1b721018318e011c9e8b27?placeholderIfAbsent=true&apiKey=c8d530c75cd1478687ed622797fda84f&format=webp")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                }
                .frame(width: 24, height: 24)
                .padding(12)
                .background(Color(red: 0.48, green: 0.75, blue: 0.29))
                .cornerRadius(6)
                .shadow(color: Color(red: 0.48, green: 0.75, blue: 0.29).opacity(0.1), radius: 3, x: 1, y: 4)
            }

            Spacer()

            Button(action: {
                // Action for second button
            }) {
                AsyncImage(url: URL(string: "https://cdn.builder.io/api/v1/image/assets/TEMP/6634c95692fa06253c201f615bdc605c35c7eba5208f67dc212aae7a5c60d58f?placeholderIfAbsent=true&apiKey=c8d530c75cd1478687ed622797fda84f&format=webp")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Image(systemName: "person")
                }
                .frame(width: 24, height: 24)
            }

            Spacer()
        }
        .padding(.vertical, 15)
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(red: 0.89, green: 0.89, blue: 0.89)),
            alignment: .top
        )
        .frame(maxWidth: 480)
    }
}