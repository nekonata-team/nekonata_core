class Location {
  const Location({
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.timestamp,
  });

  factory Location.fromJson(Map<dynamic, dynamic> json) {
    return Location(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      speed: json['speed'] as double,
      timestamp: json['timestamp'] as double,
    );
  }
  final double latitude;
  final double longitude;
  final double speed;
  final double timestamp;

  @override
  String toString() {
    return 'time: $timestamp, lat: $latitude, lng: $longitude, speed: $speed';
  }
}
