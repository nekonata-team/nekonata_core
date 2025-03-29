import CoreLocation
import Flutter
import UIKit
import os

@available(iOS 14.0, *)
let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app.nekonata", category: "🐱")

@available(iOS 14.0, *)
public class NekonataLocationFetcher {
    static public let shared = NekonataLocationFetcherPlugin()

    private init() {}
}

@available(iOS 14.0, *)
public class NekonataLocationFetcherPlugin: NSObject, FlutterPlugin,
    LocationFetcherDelegate
{
    private var channel: FlutterMethodChannel?
    private var lastUpdateTimestamp: TimeInterval = 0
    private var updateInterval: TimeInterval = 5
    private var updateWorkItem: DispatchWorkItem?

    private var locationFetcher: LocationFetcher {
        if _locationFetcher == nil {
            let mode = Mode(rawValue: Store.mode) ?? Mode.hybrid

            if #available(iOS 18.0, *) {
                switch mode {
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

        logger.notice("🐱 NekonataLocationFetcherPlugin register called")

        instance.channel = FlutterMethodChannel(
            name: "nekonata_location_fetcher", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: instance.channel!)
        registrar.addApplicationDelegate(instance)
    }

    public func handle(
        _ call: FlutterMethodCall, result: @escaping FlutterResult
    ) {
        DispatchQueue.main.async {

            switch call.method {
            case "configure":
                do {
                    try self.configure(call)
                    result(nil)
                } catch {
                    result(
                        FlutterError(
                            code: "error", message: error.localizedDescription,
                            details: nil))
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
                    Keys.useBackgroundActivitySessionManager: Store
                        .useBackgroundActivitySessionManager,
                    Keys.hasLocationDidFinishLaunchingWithOptions: Store
                        .hasLocationDidFinishLaunchingWithOptions,
                    Keys.distanceFilter: Store.distanceFilter,
                    Keys.interval: Store.interval,
                ])
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func configure(_ call: FlutterMethodCall) throws {
        guard let args = call.arguments as? [String: Any] else {
            throw NSError(
                domain: "Invalid arguments", code: 0, userInfo: nil
            )
        }

        if let mode = args[Keys.mode] as? String {
            if Mode(rawValue: mode) != nil {
                Store.mode = mode
            } else {
                throw NSError(
                    domain: "Invalid arguments", code: 0, userInfo: nil
                )
            }
        }
        if let useBackgroundActivitySessionManager = args[
            Keys.useBackgroundActivitySessionManager] as? Bool
        {
            Store.useBackgroundActivitySessionManager =
                useBackgroundActivitySessionManager
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
        updateInterval = TimeInterval(Store.interval)
        locationFetcher.start()

        if #available(iOS 17.0, *) {
            BackgroundActivitySessionManager.activate()
        }

        Store.isActivated = true

        logger.notice("🐱 Start location fetching")
    }

    private func stop() {
        locationFetcher.stop()

        if #available(iOS 17.0, *) {
            BackgroundActivitySessionManager.invalidate()
        }

        Store.isActivated = false

        logger.notice("🐱 Stop location fetching")
    }

    func locationFetcher(
        _ fetcher: any LocationFetcher, didUpdateLocation location: CLLocation
    ) {
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

        DispatchQueue.main.asyncAfter(
            deadline: .now() + delay, execute: workItem)
        updateWorkItem = workItem
    }

    private func callback(_ location: CLLocation) {
        let batteryLevel = UIDevice.current.batteryLevel
        let battery = batteryLevel >= 0 ? Int(batteryLevel * 100) : -1

        let json: [String: Any] = [
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "speed": location.speed,
            "timestamp": location.timestamp.timeIntervalSince1970 * 1000,  // convert to milliseconds
            "bearing": location.course,
            "battery": battery,
        ]

        logger.info("🐱 callback from Swift")
        channel?.invokeMethod("callback", arguments: json)
    }
}

/// lifecycle
@available(iOS 14.0, *)
extension NekonataLocationFetcherPlugin {
    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [AnyHashable: Any] = [:]
    ) -> Bool {
        logger.info(
            "🐱 NekonataLocationFetcherPlugin didFinishLaunchingWithOptions: \(launchOptions)"
        )
        if let launchOptions = launchOptions
            as? [UIApplication.LaunchOptionsKey: Any]
        {
            logger.notice(
                "🐱 hasLocationDidFinishLaunchingWithOptions: \(launchOptions[.location] != nil)"
            )
            Store.hasLocationDidFinishLaunchingWithOptions =
                launchOptions[.location] != nil
        } else {
            Store.hasLocationDidFinishLaunchingWithOptions = false
        }

        UIDevice.current.isBatteryMonitoringEnabled = true

        if Store.isActivated {
            start()
        }

        return true
    }
}
