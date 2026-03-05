import CoreLocation

@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    var lastLocation: CLLocation?
    var locationName: String?
    var authorizationStatus: CLAuthorizationStatus
    var isLoading = false

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation?, Never>?
    private let geocoder = CLGeocoder()

    override init() {
        authorizationStatus = CLLocationManager().authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    // MARK: - Permission

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    // MARK: - One-time location

    func requestLocation() async -> CLLocation? {
        // If we already have a recent location (< 60s old), reuse it
        if let last = lastLocation,
           Date.now.timeIntervalSince(last.timestamp) < 60 {
            return last
        }

        isLoading = true

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            manager.requestLocation()
        }
    }

    // MARK: - Reverse Geocoding

    func reverseGeocode(_ location: CLLocation) async -> String? {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else { return nil }

            var parts: [String] = []
            if let name = placemark.name { parts.append(name) }
            if let city = placemark.locality { parts.append(city) }
            if let state = placemark.administrativeArea { parts.append(state) }

            // If name equals city, don't repeat it
            if parts.count >= 2 && parts[0] == parts[1] {
                parts.removeFirst()
            }

            let result = parts.joined(separator: ", ")
            locationName = result
            return result
        } catch {
            return nil
        }
    }

    /// Convenience: get location + place name in one call
    func requestLocationWithName() async -> (location: CLLocation, name: String?)? {
        guard let location = await requestLocation() else { return nil }
        let name = await reverseGeocode(location)
        return (location, name)
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        let c = continuation
        continuation = nil
        Task { @MainActor in
            self.lastLocation = location
            self.isLoading = false
        }
        c?.resume(returning: location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let c = continuation
        continuation = nil
        Task { @MainActor in
            self.isLoading = false
        }
        c?.resume(returning: nil)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
        }
    }
}
