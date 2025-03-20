import 'package:flutter/foundation.dart';
import 'package:nekonata_location_fetcher/nekonata_location_fetcher.dart'
    show NekonataLocationFetcher;

/// Data model for [NekonataLocationFetcher].
@immutable
class Location {
  /// Creates a [Location] instance.
  ///
  /// All parameters are required.
  const Location({
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.timestamp,
    required this.bearing,
    required this.battery,
  });

  /// Creates a [Location] instance from a JSON map.
  ///
  /// This is used for internal. But you can use this if you want.
  factory Location.fromJson(Map<dynamic, dynamic> json) {
    return Location(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      speed: json['speed'] as double,
      timestamp: json['timestamp'] as double,
      bearing: json['bearing'] as double,
      battery: json['battery'] as int,
    );
  }

  /// The latitude of the location.
  final double latitude;

  /// The longitude of the location.
  final double longitude;

  /// The speed at the location.
  final double speed;

  /// The timestamp of the location data.
  ///
  /// This is the number of milliseconds since epoch.
  final double timestamp;

  /// The bearing of the location.
  ///
  /// north: 0.0, east: 90.0, south: 180.0, west: 270.0
  final double bearing;

  /// The battery level at the location.
  final int battery;

  /// Returns a string representation of the [Location] instance.
  @override
  String toString() {
    return 'Location{latitude: $latitude, longitude: $longitude, speed: $speed,'
        ' timestamp: $dateTime, bearing: $bearing, battery: $battery}';
  }

  /// The timestamp of the location data as [DateTime].
  DateTime get dateTime =>
      DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
}
