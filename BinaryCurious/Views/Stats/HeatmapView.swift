import SwiftUI
import SwiftData
import MapKit

struct HeatmapView: View {
    var focusCoordinate: CLLocationCoordinate2D? = nil
    var focusSightingID: UUID? = nil

    @Query(sort: \Sighting.captureDate, order: .reverse) private var sightings: [Sighting]
    @State private var selectedSighting: Sighting?

    private var sightingsWithLocation: [Sighting] {
        sightings.filter { $0.coordinate != nil }
    }

    private var initialRegion: MKCoordinateRegion {
        if let focus = focusCoordinate {
            return MKCoordinateRegion(
                center: focus,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
        }

        let coords = sightingsWithLocation.compactMap(\.coordinate)
        guard !coords.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
            )
        }

        let lats = coords.map(\.latitude)
        let lons = coords.map(\.longitude)
        let center = CLLocationCoordinate2D(
            latitude: (lats.min()! + lats.max()!) / 2,
            longitude: (lons.min()! + lons.max()!) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.01, (lats.max()! - lats.min()!) * 1.5),
            longitudeDelta: max(0.01, (lons.max()! - lons.min()!) * 1.5)
        )
        return MKCoordinateRegion(center: center, span: span)
    }

    var body: some View {
        Map(initialPosition: .region(initialRegion)) {
            ForEach(sightingsWithLocation) { sighting in
                if let coord = sighting.coordinate {
                    Annotation(
                        markerLabel(for: sighting),
                        coordinate: coord
                    ) {
                        Button {
                            withAnimation(.spring(duration: 0.3)) {
                                if selectedSighting?.id == sighting.id {
                                    selectedSighting = nil
                                } else {
                                    selectedSighting = sighting
                                }
                            }
                        } label: {
                            SightingMarkerView(
                                rarityScore: sighting.rarityScore,
                                isSelected: selectedSighting?.id == sighting.id
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .annotationTitles(.hidden)
                }
            }
        }
        .navigationTitle("Sighting Map")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) {
            if let sighting = selectedSighting {
                sightingPreviewCard(for: sighting)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding()
            }
        }
        .task {
            if let id = focusSightingID, selectedSighting == nil {
                selectedSighting = sightingsWithLocation.first { $0.id == id }
            }
        }
        .overlay {
            if sightingsWithLocation.isEmpty {
                ContentUnavailableView(
                    "No Locations",
                    systemImage: "map",
                    description: Text("Sightings with location data will appear here.")
                )
                .background(.ultraThinMaterial)
            }
        }
    }

    // MARK: - Marker Label

    private func markerLabel(for sighting: Sighting) -> String {
        if let name = sighting.locationName, !name.isEmpty {
            return name
        }
        return sighting.captureDate.formatted(.dateTime.month(.defaultDigits).day())
    }

    // MARK: - Map Marker Color

    private func markerColor(for score: Int) -> Color {
        switch score {
        case 1: .green
        case 2: .green
        case 3: .blue
        case 4: .purple
        case 5: .orange
        default: .green
        }
    }

    // MARK: - Preview Card

    @ViewBuilder
    private func sightingPreviewCard(for sighting: Sighting) -> some View {
        NavigationLink {
            SightingDetailView(sighting: sighting)
        } label: {
            HStack(spacing: 12) {
                SightingThumbnailView(sighting: sighting, size: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text(sighting.locationName ?? sighting.captureDate.formatted(.dateTime.month(.wide).day().year()))
                        .font(.subheadline.bold())
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        if sighting.totalMatchCount > 0 {
                            Text("\(sighting.totalMatchCount) match\(sighting.totalMatchCount == 1 ? "" : "es")")
                                .font(.caption.bold())
                                .foregroundColor(.green)
                        }

                        Text(Constants.Rarity.label(for: sighting.rarityScore))
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(markerColor(for: sighting.rarityScore).opacity(0.2))
                            .foregroundColor(markerColor(for: sighting.rarityScore))
                            .clipShape(Capsule())
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sighting Marker

private struct SightingMarkerView: View {
    let rarityScore: Int
    let isSelected: Bool

    private var color: Color {
        switch rarityScore {
        case 1: .green
        case 2: .green
        case 3: .blue
        case 4: .purple
        case 5: .orange
        default: .green
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.4))
                .frame(width: isSelected ? 48 : 40, height: isSelected ? 48 : 40)
            Circle()
                .fill(color)
                .frame(width: isSelected ? 30 : 24, height: isSelected ? 30 : 24)
            Text("\(TrackedNumberService.shared.primaryNumber)")
                .font(.system(size: isSelected ? 12 : 10, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}
