import SwiftUI

enum SightingCategory: String, CaseIterable, Identifiable {
    case printed
    case digital
    case natural
    case handwritten
    case architectural
    case serendipitous

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var description: String {
        switch self {
        case .printed: "Books, receipts, packaging"
        case .digital: "Screens, clocks, displays"
        case .natural: "Addresses, license plates, mile markers"
        case .handwritten: "Notes, whiteboards, graffiti"
        case .architectural: "Room numbers, floors, building addresses"
        case .serendipitous: "Random totals, timestamps, unexpected places"
        }
    }

    var iconName: String {
        switch self {
        case .printed: "book.fill"
        case .digital: "desktopcomputer"
        case .natural: "leaf.fill"
        case .handwritten: "pencil"
        case .architectural: "building.2.fill"
        case .serendipitous: "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .printed: .goldDark
        case .digital: .purpleLight
        case .natural: .successGreen
        case .handwritten: .goldPrimary
        case .architectural: .goldLight
        case .serendipitous: .purpleAccent
        }
    }
}
