import SwiftUI

enum AppTab: String, CaseIterable {
    case sightings
    case capture
    case albums
    case profile

    var title: String {
        switch self {
        case .sightings: "Sightings"
        case .capture: "Capture"
        case .albums: "Albums"
        case .profile: "Profile"
        }
    }

    var iconName: String {
        switch self {
        case .sightings: "eye"
        case .capture: "camera.fill"
        case .albums: "rectangle.stack.fill"
        case .profile: "person.fill"
        }
    }
}
