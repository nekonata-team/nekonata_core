import 'package:flutter/foundation.dart';
import 'package:nekonata_location_fetcher/nekonata_location_fetcher.dart';

/// Configuration for [NekonataLocationFetcher].
@immutable
class Configuration {
  /// Creates a [Configuration] instance.
  const Configuration({
    required this.distanceFilter,
    required this.interval,
    this.useCLLocationUpdate,
    this.useBackgroundActivitySessionManager,
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
      useCLLocationUpdate: json['useCLLocationUpdate'] as bool?,
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
  final bool? useCLLocationUpdate;

  /// Whether to use BackgroundActivitySessionManager. Only available on iOS.
  final bool? useBackgroundActivitySessionManager;

  /// The title of the notification. Only available on Android.
  final String? notificationTitle;

  /// The text of the notification. Only available on Android.
  final String? notificationText;
}
