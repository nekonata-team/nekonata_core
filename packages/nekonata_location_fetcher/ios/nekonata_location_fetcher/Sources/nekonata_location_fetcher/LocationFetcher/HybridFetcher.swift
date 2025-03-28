import CoreLocation

@available(iOS 18.0, *)
class HybridFetcher: NSObject, LocationFetcher, CLLocationManagerDelegate {
    weak var delegate: LocationFetcherDelegate?
    private var locationManager: CLLocationManager?
    
    private var updateTask: Task<Void, Error>?
    // 最後に通知した位置情報を保持
    // CLLocationUpdateにはdistanceFilterがないため、距離を算出してエミュレートする
    private var lastLocation: CLLocation?
    
    func start() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.pausesLocationUpdatesAutomatically = false
        
        locationManager?.startMonitoringSignificantLocationChanges()
    }

    func stop() {
        locationManager?.stopMonitoringSignificantLocationChanges()
        locationManager = nil
        
        stopLiveUpdates()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if updateTask == nil {
            debugPrint(".didUpdateLocations")
            startLiveUpdates()
        } else {
            debugPrint(".didUpdateLocations: ignore")
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        debugPrint("Failed to find user's location: \(error.localizedDescription)")
    }

    
    private func startLiveUpdates() {
        debugPrint("Start liveUpdates")
        
        let distanceFilter = Store.distanceFilter
        
        updateTask = Task { [weak self] in
            let _ = CLServiceSession(authorization: .always)
            if Store.useBackgroundActivitySessionManager {
                BackgroundActivitySessionManager.activate()
            }

            for try await update in CLLocationUpdate.liveUpdates() {
                guard let self = self else { return }
                guard let location = update.location else { continue }
                
//                debugPrint(location)
               
                if update.stationary {
                    debugPrint("Stationary")
                    self.update(location)
                    break
                } else {
                    // 距離を確認して、しきい値を超える場合はupdateを呼ぶ
                    if self.isOverOrNil(location, distanceFilter) {
                        self.update(location)
                    }
                }
            }
            
            BackgroundActivitySessionManager.invalidate()
            self?.updateTask = nil
        }
    }
    
    private func stopLiveUpdates() {
        debugPrint("Stop liveUpdates")
        updateTask?.cancel()
        updateTask = nil
        lastLocation = nil
    }

    private func isOverOrNil(_ location: CLLocation, _ distanceFilter: Double) -> Bool {
        self.lastLocation == nil || location.distance(from: self.lastLocation!) >= distanceFilter
    }
    
    private func update(_ location: CLLocation) {
        self.lastLocation = location
        self.delegate?.locationFetcher(self, didUpdateLocation: location)
    }
}
