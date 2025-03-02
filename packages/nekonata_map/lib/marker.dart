import 'package:flutter/foundation.dart';

@immutable
class MarkerData {
  final String id;
  final double longitude;
  final double latitude;
  final double? minWidth;
  final double? minHeight;
  final Uint8List? image;

  const MarkerData({
    required this.id,
    required this.longitude,
    required this.latitude,
    this.minWidth,
    this.minHeight,
    this.image,
  });

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
