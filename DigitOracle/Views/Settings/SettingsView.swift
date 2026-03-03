import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var sightings: [Sighting]
    @State private var showingDeleteConfirmation = false
    @State private var showingResetConfirmation = false
    @State private var showingScanner = false
    @State private var storageStats: ImageStorageService.StorageStats?

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        Form {
            Section("The Seeker") {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.accentColor)
                    VStack(alignment: .leading) {
                        Text(profile?.displayName ?? "Seeker")
                            .font(.headline)
                        if let joined = profile?.joinedDate {
                            Text("Joined \(joined.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Rituals") {
                NavigationLink(value: SettingsDestination.trackedNumbers) {
                    Label("Sacred Numbers", systemImage: "number.square")
                }
                NavigationLink(value: SettingsDestination.notifications) {
                    Label("Omens & Whispers", systemImage: "bell.badge")
                }
                NavigationLink(value: SettingsDestination.detection) {
                    Label("The Oracle's Eye", systemImage: "eye")
                }
            }

            Section("The Archive") {
                HStack {
                    Text("Visions")
                    Spacer()
                    Text("\(sightings.count)")
                        .foregroundStyle(.secondary)
                }
                if let stats = storageStats, stats.totalBytes > 0 {
                    HStack {
                        Text("Storage Used")
                        Spacer()
                        Text(ByteCountFormatter.string(fromByteCount: stats.totalBytes, countStyle: .file))
                            .foregroundStyle(.secondary)
                    }
                }
                Button {
                    showingScanner = true
                } label: {
                    Label("Peer into the Archive", systemImage: "magnifyingglass")
                }
            }

            Section("The Inscription") {
                HStack {
                    Text("Version")
                    Spacer()
                    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
                    Text("0.47.\(build)")
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
                Button("Erase All Visions", role: .destructive) {
                    showingDeleteConfirmation = true
                }
                Button("Silence the Oracle", role: .destructive) {
                    showingResetConfirmation = true
                }
            }
        }
        .sheet(isPresented: $showingScanner, onDismiss: { refreshStorageStats() }) {
            LibraryScannerView()
        }
        .onAppear { refreshStorageStats() }
        .navigationTitle("Sanctum")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: SettingsDestination.self) { dest in
            switch dest {
            case .trackedNumbers:
                NumberSelectionView(isOnboarding: false)
            case .notifications:
                NotificationSettingsView()
            case .detection:
                OCRSettingsView()
            }
        }
        .alert("Erase All Visions?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Erase Everything", role: .destructive) {
                deleteAllSightings()
            }
        } message: {
            Text("This shall permanently banish all thy visions from the Oracle's memory. This cannot be undone.")
        }
        .alert("Silence the Oracle?", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Silence", role: .destructive) {
                deleteAllSightings()
                TrackedNumberService.shared.resetToDefaults()
                UserDefaults.standard.removeObject(forKey: Constants.OCR.useFastModeKey)
                UserDefaults.standard.removeObject(forKey: Constants.OCR.useLanguageCorrectionKey)
                UserDefaults.standard.removeObject(forKey: Constants.LiveDetector.throttleIntervalKey)
                UserDefaults.standard.removeObject(forKey: Constants.LiveDetector.cooldownDurationKey)
                UserDefaults.standard.removeObject(forKey: Constants.LiveDetector.confirmationFramesKey)
            }
        } message: {
            Text("This shall erase all visions and silence the Oracle. Thou shalt begin the ritual anew.")
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
    case detection
}
