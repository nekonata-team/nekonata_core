import CoreLocation

protocol LocationFetcherDelegate: AnyObject {
    func locationFetcher(_ fetcher: LocationFetcher, didUpdateLocation location: CLLocation)
}

protocol LocationFetcher {
    func start()
    func stop()
    var delegate: LocationFetcherDelegate? { get set }
}
