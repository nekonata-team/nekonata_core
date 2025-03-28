# nekonata_location_fetcher

Wrapper of `CLLocationManager` and `FusedLocationProviderClient`

This can fetch location data even if app was killed.

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

```dart
import 'package:nekonata_location_fetcher/model.dart';
import 'package:nekonata_location_fetcher/nekonata_location_fetcher.dart';

@pragma('vm:entry-point')
void _callback(Location location) {
  SharedPreferences.getInstance().then((prefs) {
    final locations = prefs.getStringList('locations') ?? [];
    locations.add(location.toString());
    prefs.setStringList('locations', locations);
    debugPrint('Location was updated');
  });
}

final fetcher = NekonataLocationFetcher();

fetcher.setCallback(_callback);

fetcher.start();

fetcher.isActivated;

fetcher.stop();
```

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

- Add `Background Modes` in `Signing & Capabilities`
  - `Location Updates`
- Add descriptions in `Info.plist`
  - `NSLocationAlwaysUsageDescription`
  - `NSLocationAlwaysAndWhenInUseUsageDescription`
  - `NSLocationWhenInUseUsageDescription`

### Android

```xml
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

### Limitation

- minSdk is **Android 26**
- minimum iOS version is **iOS 13**
  - for use `Task`
