import Foundation

struct PortalModel: Identifiable, Codable, Equatable {
    let id: String
    var title: String
    var subtitle: String
    var city: String
    var imageItems: [ImageItem]
    var about: String
    var categories: [PortalCategory]
    var leads: [LeadModel]

    // Computed property for display
    var categoriesText: String {
        categories.map { $0.rawValue }.joined(separator: ", ")
    }

    // Sample for previews
    static let sample = PortalModel(
        id: "1",
        title: "Sample Portal",
        subtitle: "A great place to connect",
        city: "New York",
        imageItems: [],
        about: "This is a sample portal description.",
        categories: [.education, .community],
        leads: []
    )
}

enum PortalCategory: String, Codable, CaseIterable {
    case education
    case community
    case business
    // Add more as needed
}

struct ImageItem: Identifiable, Codable, Equatable {
    let id: String
    let url: String
}

struct LeadModel: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let imageUrl: String
}
