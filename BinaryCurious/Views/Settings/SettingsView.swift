import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var showingDeleteConfirmation = false
    @State private var showingResetConfirmation = false
    @State private var showingScanner = false
    @State private var storageStats: ImageStorageService.StorageStats?

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
                if let stats = storageStats {
                    HStack {
                        Text("Images")
                        Spacer()
                        Text("\(stats.fileCount)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Storage Used")
                        Spacer()
                        Text(stats.totalBytes == 0 ? "0" : ByteCountFormatter.string(fromByteCount: stats.totalBytes, countStyle: .file))
                            .foregroundStyle(.secondary)
                    }
                }
                Button {
                    showingScanner = true
                } label: {
                    Label("Scan Library", systemImage: "magnifyingglass")
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

            Section {
                Button("Delete All Sightings", role: .destructive) {
                    showingDeleteConfirmation = true
                }
                Button("Reset App", role: .destructive) {
                    showingResetConfirmation = true
                }
            }
        }
        .sheet(isPresented: $showingScanner, onDismiss: { refreshStorageStats() }) {
            LibraryScannerView()
        }
        .onAppear { refreshStorageStats() }
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
        .alert("Reset App?", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                deleteAllSightings()
                TrackedNumberService.shared.resetToDefaults()
            }
        } message: {
            Text("This will delete all sightings and reset the app to its initial state. You will go through onboarding again.")
        }
    }

    private func deleteAllSightings() {
        let sightings = (try? modelContext.fetch(FetchDescriptor<Sighting>())) ?? []
        for sighting in sightings {
            modelContext.delete(sighting)
        }
        try? modelContext.save()
        ImageStorageService.shared.deleteAllImages()
        refreshStorageStats()
    }

    private func refreshStorageStats() {
        storageStats = ImageStorageService.shared.calculateStorageStats()
    }
}

enum SettingsDestination: Hashable {
    case trackedNumbers
    case notifications
}
