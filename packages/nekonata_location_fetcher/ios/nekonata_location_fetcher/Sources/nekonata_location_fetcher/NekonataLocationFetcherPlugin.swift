import CoreLocation
import Flutter
import UIKit


@available(iOS 13.0, *)
public class NekonataLocationFetcher {
    static public let shared = NekonataLocationFetcherPlugin()
    
    private init() {}
}

@available(iOS 13.0, *)
public class NekonataLocationFetcherPlugin: NSObject, FlutterPlugin, LocationFetcherDelegate {
    public var register: ((FlutterEngine) -> Void)?

    private var flutterEngine = FlutterEngine(
        name: Bundle.main.bundleIdentifier ?? "nekonata_location_fetcher")
    private var channel: FlutterMethodChannel?
    
    private var isDispatched: Bool = false
    private var lastUpdateTimestamp: TimeInterval = 0
    private var updateInterval: TimeInterval = 5
    private var updateWorkItem: DispatchWorkItem?
    
    
    private var locationFetcher: LocationFetcher {
        if _locationFetcher == nil {
            let mode = Mode(rawValue: Store.mode) ?? Mode.hybrid
            
            if #available(iOS 18.0, *) {
                switch (mode) {
                case .hybrid:
                    debugPrint("Use HybridFetcher")
                    _locationFetcher = HybridFetcher()
                case .locationManager:
                    debugPrint("Use CLLocationManagerFetcher")
                    _locationFetcher = CLLocationManagerFetcher()
                case .locationUpdate:
                    debugPrint("Use LocationUpdateFetcher")
                    _locationFetcher = CLLocationUpdateFetcher()
                }

            } else {
                // Fallback
                debugPrint("Fallback. Use CLLocationManagerFetcher")
                _locationFetcher = CLLocationManagerFetcher()
            }
            _locationFetcher?.delegate = self
        }
        return _locationFetcher!
    }
    private var _locationFetcher: LocationFetcher?


    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = NekonataLocationFetcher.shared
        
        NSLog("🐱 NekonataLocationFetcherPlugin register called")
        
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
            case Keys.isActivated:
                result(Store.isActivated)
            case "configuration":
                result([
                    Keys.mode: Store.mode,
                    Keys.useBackgroundActivitySessionManager: Store.useBackgroundActivitySessionManager,
                    Keys.hasLocationDidFinishLaunchingWithOptions: Store.hasLocationDidFinishLaunchingWithOptions,
                    Keys.distanceFilter: Store.distanceFilter,
                    Keys.interval: Store.interval,
                ])
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
        
        dispatch()
        
        NSLog("🐱 Set callback successfully")
    }

    private func configure(_ call: FlutterMethodCall) throws {
        guard let args = call.arguments as? [String: Any] else {
            throw NSError(
                domain: "Invalid arguments", code: 0, userInfo: nil
            )
        }

        if let mode = args[Keys.mode] as? String {
            if let _ = Mode(rawValue: mode) {
                Store.mode = mode
            } else {
                throw NSError(
                    domain: "Invalid arguments", code: 0, userInfo: nil
                )
            }
        }
        if let useBackgroundActivitySessionManager = args[Keys.useBackgroundActivitySessionManager] as? Bool {
            Store.useBackgroundActivitySessionManager = useBackgroundActivitySessionManager
        }
        if let distanceFilter = args[Keys.distanceFilter] as? Double {
            Store.distanceFilter = distanceFilter
        }
        if let interval = args[Keys.interval] as? Int {
            Store.interval = interval
        }
        
        restart()
    }
    
    private func restart() {
        let wasActivated = Store.isActivated
        stop()
        _locationFetcher = nil
        if wasActivated {
            start()
        }
    }

    private func start() {
        dispatch()
        
        updateInterval = TimeInterval(Store.interval)
        locationFetcher.start()
        
        if #available(iOS 17.0, *) {
            BackgroundActivitySessionManager.activate()
        }
        
        Store.isActivated = true

        NSLog("🐱 Start location fetching")
    }

    private func stop() {
        locationFetcher.stop()
        
        if #available(iOS 17.0, *) {
            BackgroundActivitySessionManager.invalidate()
        }
        
        Store.isActivated = false

        NSLog("🐱 Stop location fetching")
    }
    
    func locationFetcher(_ fetcher: any LocationFetcher, didUpdateLocation location: CLLocation) {
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
            guard let self = self, let channel = self.channel else {
                debugPrint("Channel is nil, cannot invoke callback")
                return
            }
            channel.invokeMethod("callback", arguments: json)
        }
    }
    
    /// Dart側のコールバックを呼び出し、callbackが呼ばれるようにする関数
    /// Dart側の_callbackを参照
    private func dispatch() {
        if let info = FlutterCallbackCache.lookupCallbackInformation(
            Int64(Store.dispatcherRawHandle)), !isDispatched
        {
            flutterEngine.run(
                withEntrypoint: info.callbackName, libraryURI: info.callbackLibraryPath)
            if let register = self.register {
                register(flutterEngine)
            }
            isDispatched = true
        }
    }
}

/// lifecycle
@available(iOS 13.0, *)
extension NekonataLocationFetcherPlugin {
    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [AnyHashable: Any] = [:]
    ) -> Bool {
        NSLog("🐱 NekonataLocationFetcherPlugin didFinishLaunchingWithOptions called. \(launchOptions)")
        if let launchOptions = launchOptions as? [UIApplication.LaunchOptionsKey: Any] {
            NSLog("🐱 launchOptions contains location: \(launchOptions[.location] != nil)")
            Store.hasLocationDidFinishLaunchingWithOptions = launchOptions[.location] != nil
        }
        
        channel = Self.createChannel(binaryMessenger: flutterEngine.binaryMessenger)
        
        UIDevice.current.isBatteryMonitoringEnabled = true

        if Store.isActivated {
            start()
        }
        
        return true
    }
}
