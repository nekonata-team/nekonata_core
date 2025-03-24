import CoreLocation

@available(iOS 18.0, *)
class CLLocationUpdateFetcher: LocationFetcher {
    weak var delegate: LocationFetcherDelegate?
    private var updateTask: Task<Void, Error>?
    
    // 最後に通知した位置情報を保持
    // CLLocationUpdateにはdistanceFilterがないため、距離を算出してエミュレートする
    private var lastReportedLocation: CLLocation?
    
    func start() {
        let distanceFilter = Store.distanceFilter
        
        updateTask?.cancel()
        updateTask = Task { [weak self] in
            defer { self?.stop() }
            
            let _ = CLServiceSession(authorization: .always)
            for try await update in CLLocationUpdate.liveUpdates() {
                guard let self = self else { return }
                guard let location = update.location else { continue }
                
                // 以前の位置情報がある場合、移動距離をチェック
                if let lastLocation = self.lastReportedLocation {
                    let distance = location.distance(from: lastLocation)
                    if distance < distanceFilter {
                        continue
                    }
                }
                
                self.lastReportedLocation = location
                self.delegate?.locationFetcher(self, didUpdateLocation: location)
            }
        }
    }
    
    func stop() {
        updateTask?.cancel()
        updateTask = nil
        lastReportedLocation = nil
    }
}
