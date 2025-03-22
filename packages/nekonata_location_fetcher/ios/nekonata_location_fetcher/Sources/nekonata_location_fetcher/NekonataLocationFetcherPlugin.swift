import CoreLocation
import Flutter
import UIKit

@available(iOS 13.0, *)
public class NekonataLocationFetcherPlugin: NSObject, FlutterPlugin {
    /// GeneratedPluginRegistrantを呼び出すために、AppDelegate側で指定する想定
    /// これにより、Dart側のcallbackで任意のライブラリのAPIを呼び出す事ができるようになる
    public static var onDispatched: ((FlutterEngine) -> Void)?

    private lazy var flutterEngine = FlutterEngine(
        name: Bundle.main.bundleIdentifier ?? "nekonata_location_fetcher")
    private var channel: FlutterMethodChannel?

    private var locationManager: CLLocationManager?
    private var lastUpdateTimestamp: TimeInterval = 0
    private var updateInterval: TimeInterval = 5
    private var updateWorkItem: DispatchWorkItem?
    
    private var updateTask: Task<Void, Error>?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = NekonataLocationFetcherPlugin()

        instance.channel = createChannel(binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: instance.channel!)
        registrar.addApplicationDelegate(instance)
    }
    
    static func createChannel(binaryMessenger: FlutterBinaryMessenger) -> FlutterMethodChannel {
        return FlutterMethodChannel(
            name: "nekonata_location_fetcher", binaryMessenger: binaryMessenger)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        DispatchQueue.main.async {

            switch call.method {
            case "setCallback":
                do {
                    try self.setCallback(call)
                    result(nil)
                } catch {
                    result(
                        FlutterError(
                            code: "error", message: error.localizedDescription, details: nil))
                }
            case "configure":
                do {
                    try self.configure(call)
                    result(nil)
                } catch {
                    result(
                        FlutterError(
                            code: "error", message: error.localizedDescription, details: nil))
                }
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
              let rawHandle = args[Keys.rawHandle] as? Int,
              let dispatcherRawHandle = args[Keys.dispatcherRawHandle] as? Int
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

        if let useCLLocationUpdate = args[Keys.useCLLocationUpdate] as? Bool {
            Store.useCLLocationUpdate = useCLLocationUpdate
        }
        if let useBackgroundLocationUpdate = args[Keys.useBackgroundActivitySessionManager] as? Bool {
            Store.useBackgroundActivitySessionManager = useBackgroundLocationUpdate
        }
        if let distanceFilter = args[Keys.distanceFilter] as? Double {
            Store.distanceFilter = distanceFilter
        }
        if let interval = args[Keys.interval] as? Int {
            Store.interval = interval
        }
    }

    private func start() {
        // 複数回startが呼ばれる場合があるので、明示的にstopする
        // リソースの開放などが主なので、重たい処理ではない
        stop()
        
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest  // BestForNavigationも検討中
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.pausesLocationUpdatesAutomatically = false

        // 保存されたデータの適用
        locationManager?.distanceFilter = Store.distanceFilter
        updateInterval = TimeInterval(Store.interval)
        
        
        if #available(iOS 18.0, *), Store.useCLLocationUpdate {
            // 複数ループを防ぐ
            updateTask?.cancel()
            updateTask = Task { [weak self] in
                defer {
                    self?.updateTask = nil
                }
                // セッションを張る
                let _ = CLServiceSession(authorization: .always)
                
                for try await update in CLLocationUpdate.liveUpdates() {
                    guard let self = self else { return }
                    if Task.isCancelled {
                        break
                    }
                    guard let location = update.location else { continue }
                    self.onUpdate(location)
                }
            }
        } else {
            locationManager?.startUpdatingLocation()
        }
        locationManager?.startMonitoringSignificantLocationChanges()
        
        if #available(iOS 17.0, *), Store.useBackgroundActivitySessionManager {
            BackgroundActivitySessionManager.activate()
        }
        
        Store.isActivated = true

        debugPrint("Start location fetching")
    }

    private func stop() {
        // for CLLocationUpdate
        updateTask?.cancel()
        updateTask = nil
        
        locationManager?.stopUpdatingLocation()
        locationManager?.stopMonitoringSignificantLocationChanges()
        locationManager = nil
       
        if #available(iOS 17.0, *) {
            BackgroundActivitySessionManager.invalidate()
        }
        
        Store.isActivated = false

        debugPrint("Stop location fetching")
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

        DispatchQueue.main.async { [weak self] in
            // debugPrint("notify callback", location.coordinate.longitude, location.coordinate.latitude)
            self?.channel?.invokeMethod("callback", arguments: json)
        }
    }
}


@available(iOS 13.0, *)
extension NekonataLocationFetcherPlugin: CLLocationManagerDelegate {
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
}

/// lifecycle
@available(iOS 13.0, *)
extension NekonataLocationFetcherPlugin {
    public func applicationDidEnterBackground(_ application: UIApplication) {
        guard Store.isActivated else { return }

        if #available(iOS 17.0, *), Store.useBackgroundActivitySessionManager {
            BackgroundActivitySessionManager.activate()
        }
    }

    public func applicationWillTerminate(_ application: UIApplication) {
        guard Store.isActivated else { return }

        // このアプリはterminatedな状態でも位置情報が必要
        // 明示的に再スタートする
        start()
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

            if channel != nil {
                channel = Self.createChannel(binaryMessenger: flutterEngine.binaryMessenger)
            }
        } else {
            debugPrint("Dispatcher not found")
        }

        UIDevice.current.isBatteryMonitoringEnabled = true

        if Store.isActivated {
            start()
        }

        return true
    }

}
