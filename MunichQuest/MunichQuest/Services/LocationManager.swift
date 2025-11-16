import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var enteredLocationId: String? = nil

    private let locationManager = CLLocationManager()
    private var previouslyNearLocations: Set<String> = []

    // Testing mode - set to false for production with real GPS
    private let testingMode = true
    
    override init() {
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        
        if testingMode {
            // Use Marienplatz coordinates for testing
            userLocation = CLLocation(latitude: 48.1374, longitude: 11.5755)
        }
    }
    
    func requestPermission() {
        if !testingMode {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func startUpdating() {
        if !testingMode {
            locationManager.startUpdatingLocation()
        }
    }
    
    func stopUpdating() {
        if !testingMode {
            locationManager.stopUpdatingLocation()
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startUpdating()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    func distance(to location: LocationData) -> Double? {
        guard let userLocation = userLocation else { return nil }
        let locationCoordinate = CLLocation(
            latitude: location.coordinates.lat,
            longitude: location.coordinates.lng
        )
        return userLocation.distance(from: locationCoordinate)
    }

    func checkProximity(to locations: [LocationData]) {
        guard let userLocation = userLocation else { return }

        var currentlyNearLocations: Set<String> = []

        for location in locations {
            let locationCoordinate = CLLocation(
                latitude: location.coordinates.lat,
                longitude: location.coordinates.lng
            )
            let distance = userLocation.distance(from: locationCoordinate)

            // Check if user is within location radius
            if distance <= Double(location.radius) {
                currentlyNearLocations.insert(location.id)

                // If this is a newly entered location (wasn't in range before)
                if !previouslyNearLocations.contains(location.id) {
                    // Trigger the entered location event
                    DispatchQueue.main.async { [weak self] in
                        self?.enteredLocationId = location.id
                    }
                }
            }
        }

        // Update the set of locations we're currently near
        previouslyNearLocations = currentlyNearLocations
    }

    func resetEnteredLocation() {
        enteredLocationId = nil
    }
}
