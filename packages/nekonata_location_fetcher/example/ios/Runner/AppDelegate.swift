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
        
        /// Add this block
        /// for register isolated callback
        NekonataLocationFetcher.shared.initialize { flutterEngine in
            /// If you use other plugins, you should call `GeneratedPluginRegistrant.register(with: flutterEngine)`
            GeneratedPluginRegistrant.register(with: flutterEngine)
        }
        /// If app launched by location event, return true
        /// for ignore Flutter initialization
        /// If Flutter initialization is not ignored, the app will fully launch even when triggered in the background.
        /// This can lead to unnecessary performance overhead.
        if launchOptions?.keys.contains(.location) ?? false {
            return true
        }
        /// Until here

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    /// For background activity session
    override func applicationDidEnterBackground(_ application: UIApplication) {
        NekonataLocationFetcher.shared.applicationDidEnterBackground(application)
    }

    /// For background activity session
    override func applicationWillEnterForeground(_ application: UIApplication) {
        NekonataLocationFetcher.shared.applicationWillEnterForeground(application)
    }
}
