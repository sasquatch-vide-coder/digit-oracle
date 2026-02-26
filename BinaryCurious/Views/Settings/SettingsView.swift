import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var showingDeleteConfirmation = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        Form {
            Section("Profile") {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.accentColor)
                    VStack(alignment: .leading) {
                        Text(profile?.displayName ?? "Spotter")
                            .font(.headline)
                        if let joined = profile?.joinedDate {
                            Text("Joined \(joined.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Preferences") {
                NavigationLink(value: SettingsDestination.trackedNumbers) {
                    Label("Tracked Numbers", systemImage: "number.square")
                }
                NavigationLink(value: SettingsDestination.notifications) {
                    Label("Notifications", systemImage: "bell.badge")
                }
            }

            Section("Data") {
                Button("Delete All Sightings", role: .destructive) {
                    showingDeleteConfirmation = true
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.47.0")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("App")
                    Spacer()
                    Text(Constants.appName)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: SettingsDestination.self) { dest in
            switch dest {
            case .trackedNumbers:
                NumberSelectionView(isOnboarding: false)
            case .notifications:
                NotificationSettingsView()
            }
        }
        .alert("Delete All Sightings?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete Everything", role: .destructive) {
                deleteAllSightings()
            }
        } message: {
            Text("This will permanently remove all your sightings and their images. This cannot be undone.")
        }
    }

    private func deleteAllSightings() {
        let sightings = (try? modelContext.fetch(FetchDescriptor<Sighting>())) ?? []
        for sighting in sightings {
            try? ImageStorageService.shared.deleteImages(for: sighting.id)
            modelContext.delete(sighting)
        }
        try? modelContext.save()
    }
}

enum SettingsDestination: Hashable {
    case trackedNumbers
    case notifications
}
