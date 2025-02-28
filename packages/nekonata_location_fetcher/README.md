# nekonata_location_fetcher

A new Flutter plugin project.

## Getting Started

This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/to/develop-plugins),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## How to Use

Check example app.

1. Request Permissions
    - **Always** Location
    - (Optional) **Notification** for Android Foreground Service Notification
2. Call setCallback
3. Call start

## Setup

### iOS

```xml
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
</array>
<key>NSLocationUsageDescription</key>
<string>We need your location to provide better services.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We need your location to provide better services even when the app is in the background.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to provide better services.</string>
```

```swift
import Flutter
import UIKit
import nekonata_location_fetcher // here

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // here
    NekonataLocationFetcherPlugin.onDispatched = { flutterEngine in
      GeneratedPluginRegistrant.register(with: flutterEngine)
    }
    //

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### Android

```xml
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```
