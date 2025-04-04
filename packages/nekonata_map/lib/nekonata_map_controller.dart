import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:nekonata_map/marker.dart';
import 'package:nekonata_map/nekonata_map.dart';

/// A controller for a [NekonataMap]
///
/// The controller can not create manually,
/// this will be created by the [NekonataMap]
class NekonataMapController {
  /// Creates a new [NekonataMapController] instance.
  /// This constructor is used internally by the [NekonataMap].
  NekonataMapController.internal(
    int id, {
    OnControllerCreated? onControllerCreated,
    OnMarkerTapped? onMarkerTapped,
    OnMapTapped? onMapTapped,
    OnZoomEnd? onZoomEnd,
  }) : _channel = MethodChannel('nekonata_map_$id') {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onMapReady':
          onControllerCreated?.call(this);
        case 'onMarkerTapped':
          onMarkerTapped?.call(call.arguments as String);
        case 'onMapTapped':
          final args = call.arguments as Map<dynamic, dynamic>;
          final latitude = args['latitude'] as double;
          final longitude = args['longitude'] as double;

          onMapTapped?.call(latitude, longitude);
        case 'onZoomEnd':
          final zoom = call.arguments as double;
          onZoomEnd?.call(zoom);
        default:
          throw MissingPluginException(call.method);
      }
    });
  }

  final MethodChannel _channel;

  /// Gets the current zoom level of the map.
  Future<double> get zoom =>
      _channel.invokeMethod<double>('zoom').then((value) => value!);

  /// Adds a marker to the map.
  Future<void> addMarker(MarkerData marker) =>
      _channel.invokeMethod('addMarker', marker.toMap());

  /// Removes a marker from the map.
  Future<void> removeMarker(String id) =>
      _channel.invokeMethod('removeMarker', id);

  /// Updates a marker on the map.
  ///
  /// This can reuse the same markers, but the id must be unique.
  Future<void> updateMarker(String id, LatLng latLng) => _channel.invokeMethod(
    'updateMarker',
    {'id': id, 'latitude': latLng.latitude, 'longitude': latLng.longitude},
  );

  /// Sets marker visibility.
  Future<void> setMarkerVisible(String id, {bool isVisible = true}) => _channel
      .invokeMethod('setMarkerVisible', {'id': id, 'isVisible': isVisible});

  /// Moves the camera to a specific location.
  Future<void> moveCamera({
    LatLng? latLng,
    double? zoom,
    double? heading,
    bool animated = true,
  }) => _channel.invokeMethod('moveCamera', {
    'latitude': latLng?.latitude,
    'longitude': latLng?.longitude,
    'zoom': zoom?.clamp(2, 20),
    'heading': heading,
    'animated': animated,
  });

  /// Sets the region of the map.
  Future<void> setRegion({
    required LatLng min,
    required LatLng max,
    int paddingPx = 0,
  }) => _channel.invokeMethod('setRegion', {
    'minLatitude': min.latitude,
    'minLongitude': min.longitude,
    'maxLatitude': max.latitude,
    'maxLongitude': max.longitude,
    'paddingPx': paddingPx,
  });
}
