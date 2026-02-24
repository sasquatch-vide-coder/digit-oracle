import SwiftUI
import SwiftData
import MapKit

struct HeatmapView: View {
    @Query(sort: \Sighting.captureDate, order: .reverse) private var sightings: [Sighting]

    private var sightingsWithLocation: [Sighting] {
        sightings.filter { $0.coordinate != nil }
    }

    private var initialRegion: MKCoordinateRegion {
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
                        sighting.locationName ?? "47",
                        coordinate: coord
                    ) {
                        ZStack {
                            Circle()
                                .fill(rarityColor(for: sighting.rarityScore).opacity(0.3))
                                .frame(width: 32, height: 32)
                            Circle()
                                .fill(rarityColor(for: sighting.rarityScore))
                                .frame(width: 16, height: 16)
                            Text("47")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
        }
        .navigationTitle("Sighting Map")
        .navigationBarTitleDisplayMode(.inline)
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

    private func rarityColor(for score: Int) -> Color {
        switch score {
        case 1: .gray
        case 2: .green
        case 3: .blue
        case 4: .purple
        case 5: .orange
        default: .gray
        }
    }
}
