import CoreLocation
import Flutter
import UIKit

public class NekonataLocationFetcherPlugin: NSObject, FlutterPlugin, CLLocationManagerDelegate {
    /// GeneratedPluginRegistrantを呼び出すために、AppDelegate側で指定する想定
    /// これにより、Dart側のcallbackで任意のライブラリのAPIを呼び出す事ができるようになる
    public static var onDispatched: ((FlutterEngine) -> Void)?

    private let flutterEngine = FlutterEngine(
        name: Bundle.main.bundleIdentifier ?? "nekonata_location_fetcher")
    private var channel: FlutterMethodChannel?

    private var locationManager: CLLocationManager?
    private var lastUpdateTimestamp: TimeInterval = 0
    private let updateInterval: TimeInterval = 5
    private var updateWorkItem: DispatchWorkItem?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = NekonataLocationFetcherPlugin()

        let channel = FlutterMethodChannel(
            name: "nekonata_location_fetcher", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: channel)

        registrar.addApplicationDelegate(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        DispatchQueue.main.async {

            switch call.method {
            case "setCallback":
                do {
                    try self.setCallback(call)
                } catch {
                    result(
                        FlutterError(
                            code: "error", message: error.localizedDescription, details: nil))
                    return
                }

                result(nil)
            case "configure":
                do {
                    try self.configure(call)
                } catch {
                    result(
                        FlutterError(
                            code: "error", message: error.localizedDescription, details: nil))
                    return
                }

                result(nil)
            case "start":
                self.start()
                result(nil)
            case "stop":
                self.stop()
                result(nil)
            case "isActivated":
                result(Store.isActivated)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func setCallback(_ call: FlutterMethodCall) throws {
        guard let args = call.arguments as? [String: Any],
            let rawHandle = args["rawHandle"] as? Int,
            let dispatcherRawHandle = args["dispatcherRawHandle"] as? Int
        else {
            throw NSError(domain: "Invalid arguments", code: 0, userInfo: nil)
        }

        Store.rawHandle = rawHandle
        Store.dispatcherRawHandle = dispatcherRawHandle
        debugPrint("Set callback successfully")
    }

    private func configure(_ call: FlutterMethodCall) throws {
        guard let args = call.arguments as? [String: Any] else {
            throw NSError(
                domain: "Invalid arguments", code: 0, userInfo: nil
            )
        }

        if let useCLServiceSession = args["useCLServiceSession"] as? Bool {
            Store.useCLServiceSession = useCLServiceSession
        }
        if let distanceFilter = args["distanceFilter"] as? Double {
            Store.distanceFilter = distanceFilter
        }
        if let interval = args["interval"] as? Int {
            Store.interval = interval
        }
    }

    private func start() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest  // BestForNavigationも検討中
        locationManager?.distanceFilter = Store.distanceFilter
        updateInterval = TimeInterval(Store.interval)
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.pausesLocationUpdatesAutomatically = false

        activateLocationWatching()

        debugPrint("Start location fetching")
    }

    private func stop() {
        inactivateLocationWatching()

        locationManager = nil

        if #available(iOS 17.0, *) {
            BackgroundActivitySessionManager.invalidate()
        }

        debugPrint("Stop location fetching")
    }

    private func activateLocationWatching() {
        Store.isActivated = true

        if #available(iOS 18.0, *), Store.useCLServiceSession {
            let _ = CLServiceSession(authorization: .always)

            Task {
                for try await update in CLLocationUpdate.liveUpdates() {
                    if !Store.isActivated {
                        break
                    }
                    guard let location = update.location else { continue }
                    onUpdate(location)
                }
            }

        } else {
            locationManager?.startUpdatingLocation()
        }

        locationManager?.startMonitoringSignificantLocationChanges()
    }

    private func inactivateLocationWatching() {
        Store.isActivated = false

        if #available(iOS 18.0, *) {
            // checking in liveUpdates loop by Store.isActivated
        } else {
            locationManager?.stopUpdatingLocation()
        }

        locationManager?.stopMonitoringSignificantLocationChanges()
    }

    public func applicationDidEnterBackground(_ application: UIApplication) {
        guard Store.isActivated else { return }

        activateLocationWatching()

        if #available(iOS 17.0, *) {
            BackgroundActivitySessionManager.activate()
        }
    }

    public func applicationWillTerminate(_ application: UIApplication) {
        guard Store.isActivated else { return }

        activateLocationWatching()
    }

    public func applicationWillEnterForeground(_ application: UIApplication) {
        if #available(iOS 17.0, *) {
            BackgroundActivitySessionManager.invalidate()
        }
    }

    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [AnyHashable: Any] = [:]
    ) -> Bool {
        if let info = FlutterCallbackCache.lookupCallbackInformation(
            Int64(Store.dispatcherRawHandle))
        {

            flutterEngine.run(
                withEntrypoint: info.callbackName, libraryURI: info.callbackLibraryPath)

            Self.onDispatched?(flutterEngine)

            channel = FlutterMethodChannel(
                name: "nekonata_location_fetcher", binaryMessenger: flutterEngine.binaryMessenger
            )
        }

        UIDevice.current.isBatteryMonitoringEnabled = true

        if Store.isActivated {
            start()
        }

        return true
    }

    public func locationManager(
        _ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]
    ) {

        guard let location = locations.last else { return }
        onUpdate(location)
    }

    public func locationManager(
        _ manager: CLLocationManager, didFailWithError error: Error
    ) {
        debugPrint("Failed to find user's location: \(error.localizedDescription)")
    }

    private func onUpdate(_ location: CLLocation) {
        // debugPrint("called", location.coordinate.longitude, location.coordinate.latitude)

        // throttle like Android FusedLocationProviderClient.setInterval
        let currentTimestamp = Date().timeIntervalSince1970
        let interval = currentTimestamp - lastUpdateTimestamp

        if interval >= updateInterval {
            callback(location)
            lastUpdateTimestamp = currentTimestamp
            return
        }

        updateWorkItem?.cancel()
        let delay = max(0, updateInterval - interval)

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }

            self.callback(location)
            self.lastUpdateTimestamp = currentTimestamp + delay
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        updateWorkItem = workItem
    }

    private func callback(_ location: CLLocation) {
        let batteryLevel = UIDevice.current.batteryLevel
        let battery = batteryLevel >= 0 ? Int(batteryLevel * 100) : -1

        let json: [String: Any] = [
            "rawHandle": Store.rawHandle,
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "speed": location.speed,
            "timestamp": location.timestamp.timeIntervalSince1970 * 1000,  // convert to milliseconds
            "bearing": location.course,
            "battery": battery,
        ]

        DispatchQueue.main.async {
            // debugPrint("notify callback", location.coordinate.longitude, location.coordinate.latitude)
            self.channel?.invokeMethod("callback", arguments: json)
        }
    }
}
