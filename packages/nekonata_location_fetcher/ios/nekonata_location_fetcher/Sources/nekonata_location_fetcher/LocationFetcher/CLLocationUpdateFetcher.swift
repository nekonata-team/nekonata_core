import CoreLocation

@available(iOS 18.0, *)
class CLLocationUpdateFetcher: LocationFetcher {
    weak var delegate: LocationFetcherDelegate?
    private var updateTask: Task<Void, Error>?
    
    // 最後に通知した位置情報を保持
    // CLLocationUpdateにはdistanceFilterがないため、距離を算出してエミュレートする
    private var lastLocation: CLLocation?
    
    func start() {
        let distanceFilter = Store.distanceFilter
        
        updateTask?.cancel()
        updateTask = Task { [weak self] in
            defer { self?.stop() }
            
            let _ = CLServiceSession(authorization: .always)
            for try await update in CLLocationUpdate.liveUpdates() {
                guard let self = self else { return }
                guard let location = update.location else { continue }
               
                // 距離を確認して、しきい値を超える場合はupdateを呼ぶ
                if self.isOverOrNil(location, distanceFilter) {
                    self.update(location)
                }
            }
        }
    }
    
    func stop() {
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
