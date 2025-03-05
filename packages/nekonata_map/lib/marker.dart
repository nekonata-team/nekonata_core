import 'package:flutter/foundation.dart';

/// Data class that represents a marker.
@immutable
class MarkerData {
  /// Creates a new [MarkerData] instance.
  const MarkerData({
    required this.id,
    required this.longitude,
    required this.latitude,
    this.minWidth,
    this.minHeight,
    this.image,
  });

  /// The unique identifier of the marker.
  final String id;

  /// The longitude of the marker.
  final double longitude;

  /// The latitude of the marker.
  final double latitude;

  /// The minimum width of the image.
  final double? minWidth;

  /// The minimum height of the image.
  final double? minHeight;

  /// The image of the marker.
  ///
  /// This is a byte array of the image.
  /// png, jpg, gif is supported.
  final Uint8List? image;

  /// Converts this instance to a map.
  ///
  /// This is used to send the data to the platform side.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'longitude': longitude,
      'latitude': latitude,
      'minWidth': minWidth,
      'minHeight': minHeight,
      'image': image,
    };
  }
}
