import Flutter
import UIKit
import nekonata_location_fetcher  // Add this line

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        NekonataLocationFetcher.shared.register = { flutterEngine in
            GeneratedPluginRegistrant.register(with: flutterEngine)
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
