import 'package:flutter/foundation.dart';
import 'package:nekonata_location_fetcher/nekonata_location_fetcher.dart';

/// Configuration for [NekonataLocationFetcher].
@immutable
class Configuration {
  /// Creates a [Configuration] instance.
  const Configuration({
    required this.distanceFilter,
    required this.interval,
    this.mode,
    this.useBackgroundActivitySessionManager,
    this.hasLocationDidFinishLaunchingWithOptions,
    this.notificationTitle,
    this.notificationText,
  });

  /// Creates a [Configuration] instance from a JSON map.
  ///
  /// This is used for internal. But you can use this if you want.
  factory Configuration.fromJson(Map<dynamic, dynamic> json) {
    return Configuration(
      distanceFilter: json['distanceFilter'] as double,
      interval: json['interval'] as int,
      mode:
          (json['mode'] as String?) != null
              ? Mode.values.firstWhere(
                (e) => e.name == json['mode'],
                orElse: () => Mode.hybrid,
              )
              : null,
      hasLocationDidFinishLaunchingWithOptions:
          json['hasLocationDidFinishLaunchingWithOptions'] as bool?,
      useBackgroundActivitySessionManager:
          json['useBackgroundActivitySessionManager'] as bool?,
      notificationTitle: json['notificationTitle'] as String?,
      notificationText: json['notificationText'] as String?,
    );
  }

  /// The distance filter for location updates. This is in meters.
  final double distanceFilter;

  /// The interval for location updates. This is in seconds.
  final int interval;

  /// Whether to use CLLocationUpdate. Only available on iOS.
  final Mode? mode;

  /// Whether to use BackgroundActivitySessionManager. Only available on iOS.
  final bool? useBackgroundActivitySessionManager;

  /// Whether the location has been launched with didFinishLaunchingWithOptions.
  /// Only available on iOS.
  final bool? hasLocationDidFinishLaunchingWithOptions;

  /// The title of the notification. Only available on Android.
  final String? notificationTitle;

  /// The text of the notification. Only available on Android.
  final String? notificationText;
}

/// The mode for [Configuration].
enum Mode {
  /// Use CLLocationUpdate
  /// and CLLocationManager.startMonitoringSignificantLocationChanges.
  ///
  /// This mode is for iOS 18.0 and later.
  /// This is the default mode.
  hybrid,

  /// Use CLLocationManager.startMonitoringSignificantLocationChanges. and
  /// CLLocationManager.startUpdatingLocation.
  ///
  /// If terminated, the location will be only updated
  /// by CLLocationManager.startMonitoringSignificantLocationChanges.
  /// This mode is fallback.
  locationManager,

  /// Use CLLocationUpdate without break.
  ///
  /// This will be needed more battery.
  /// This mode is for iOS 18.0 and later.
  locationUpdate,
}
