import CoreLocation
import Flutter
import UIKit

public class NekonataLocationFetcherPlugin: NSObject, FlutterPlugin, CLLocationManagerDelegate {
  private var locationManager: CLLocationManager?
  private var channel: FlutterMethodChannel?
  private let flutterEngine = FlutterEngine(
    name: Bundle.main.bundleIdentifier ?? "nekonata_location_fetcher")

  public static var onDispatched: ((FlutterEngine) -> Void)?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = NekonataLocationFetcherPlugin()

    let channel = FlutterMethodChannel(
      name: "nekonata_location_fetcher", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: channel)

    registrar.addApplicationDelegate(instance)
    debugPrint("Registered")
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "setCallback":
      do {
        try setCallback(call)
      } catch {
        result(FlutterError(code: "error", message: error.localizedDescription, details: nil))
        return
      }

      result(nil)
    case "setAndroidNotification":
      debugPrint("setAndroidNotification is ignored on iOS")
      result(nil)
    case "start":
      start()
      result(nil)
    case "stop":
      stop()
      result(nil)
    case "isActivated":
      result(Store.isActivated)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func setCallback(_ call: FlutterMethodCall) throws {
    guard let args = call.arguments as? [String: Any] else {
      throw NSError(
        domain: "Invalid arguments", code: 0, userInfo: nil
      )
    }

    Store.rawHandle = args["rawHandle"] as! Int
    Store.dispatcherRawHandle = args["dispatcherRawHandle"] as! Int

    debugPrint(
      "Set callback successfully"
    )
  }

  private func start() {
    locationManager = CLLocationManager()
    locationManager?.delegate = self
    // locationManager?.desiredAccuracy = kCLLocationAccuracyBest
    locationManager?.desiredAccuracy = kCLLocationAccuracyBestForNavigation
    locationManager?.distanceFilter = 10
    locationManager?.allowsBackgroundLocationUpdates = true
    locationManager?.pausesLocationUpdatesAutomatically = false
    // locationManager?.requestAlwaysAuthorization()
    locationManager?.startUpdatingLocation()
    locationManager?.startMonitoringSignificantLocationChanges()

    Store.isActivated = true

    debugPrint("Start location fetching")
  }

  private func stop() {
    locationManager?.stopUpdatingLocation()
    locationManager?.stopMonitoringSignificantLocationChanges()
    locationManager = nil

    Store.isActivated = false

    debugPrint("Stop location fetching")
  }

  public func applicationDidEnterBackground(_ application: UIApplication) {
    locationManager?.startUpdatingLocation()
    locationManager?.startMonitoringSignificantLocationChanges()
  }

  public func applicationWillTerminate(_ application: UIApplication) {
    locationManager?.startMonitoringSignificantLocationChanges()
  }

  public func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [AnyHashable: Any] = [:]
  ) -> Bool {
    debugPrint("NekonataLocationFetcherPlugin Did finish launching with options")
    if let info = FlutterCallbackCache.lookupCallbackInformation(Int64(Store.dispatcherRawHandle)) {

      flutterEngine.run(withEntrypoint: info.callbackName, libraryURI: info.callbackLibraryPath)

      Self.onDispatched?(flutterEngine)

      channel = FlutterMethodChannel(
        name: "nekonata_location_fetcher", binaryMessenger: flutterEngine.binaryMessenger
      )
    }

    if Store.isActivated {
      start()
    }

    return true
  }

  public func locationManager(
    _ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]
  ) {
    guard let location = locations.last else { return }
    let json: [String: Any] = [
      "rawHandle": UserDefaults.standard.integer(forKey: "rawHandle"),
      "latitude": location.coordinate.latitude,
      "longitude": location.coordinate.longitude,
      "speed": location.speed,
      "timestamp": location.timestamp.timeIntervalSince1970,
    ]
    channel?.invokeMethod("callback", arguments: json)
  }

  public func locationManager(
    _ manager: CLLocationManager, didFailWithError error: Error
  ) {
    debugPrint("Failed to find user's location: \(error.localizedDescription)")
  }
}
