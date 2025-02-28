import 'package:nekonata_location_fetcher/nekonata_location_fetcher.dart'
    show NekonataLocationFetcher;

/// Data model for [NekonataLocationFetcher].
class Location {
  /// Creates a [Location] instance.
  ///
  /// All parameters are required.
  const Location({
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.timestamp,
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
    );
  }

  /// The latitude of the location.
  final double latitude;

  /// The longitude of the location.
  final double longitude;

  /// The speed at the location.
  final double speed;

  /// The timestamp of the location data.
  final double timestamp;

  /// Returns a string representation of the [Location] instance.
  @override
  String toString() {
    return 'time: $timestamp, lat: $latitude, lng: $longitude, speed: $speed';
  }
}
