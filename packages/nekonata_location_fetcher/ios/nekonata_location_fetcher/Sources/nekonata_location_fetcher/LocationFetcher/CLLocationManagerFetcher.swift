import CoreLocation

class CLLocationManagerFetcher: NSObject, LocationFetcher, CLLocationManagerDelegate {
    weak var delegate: LocationFetcherDelegate?
    private var locationManager: CLLocationManager?

    func start() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.pausesLocationUpdatesAutomatically = false
        locationManager?.distanceFilter = Store.distanceFilter
        
        locationManager?.startUpdatingLocation()
        locationManager?.startMonitoringSignificantLocationChanges()
    }

    func stop() {
        locationManager?.stopUpdatingLocation()
        locationManager?.stopMonitoringSignificantLocationChanges()
        locationManager = nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        delegate?.locationFetcher(self, didUpdateLocation: location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        debugPrint("Failed to find user's location: \(error.localizedDescription)")
    }
}
