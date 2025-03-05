import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:nekonata_map/marker.dart';

/// Callback typedef that will be called when a marker is tapped.
typedef OnMarkerTapped = void Function(String id);

/// Callback typedef that will be called when the map is tapped.
typedef OnMapTapped = void Function(double latitude, double longitude);

/// Callback typedef that will be called when the zoom level of the map changes.
typedef OnZoomEnd = void Function(double zoom);

/// Callback typedef that will be called when a controller is created.
typedef OnControllerCreated = void Function(NekonataMapController controller);

/// A widget that displays a map.
class NekonataMap extends StatelessWidget {
  /// Creates a new [NekonataMap] instance.
  const NekonataMap({
    super.key,
    this.latitude,
    this.longitude,
    this.onControllerCreated,
    this.onMarkerTapped,
    this.onMapTapped,
    this.onZoomEnd,
  });

  /// The initial latitude of the map.
  final double? latitude;

  /// The initial longitude of the map.
  final double? longitude;

  /// Callback that will be called when a controller is created.
  final OnControllerCreated? onControllerCreated;

  /// Callback that will be called when a marker is tapped.
  final OnMarkerTapped? onMarkerTapped;

  /// Callback that will be called when the map is tapped.
  final OnMapTapped? onMapTapped;

  /// Callback that will be called when the zoom level of the map changes.
  final OnZoomEnd? onZoomEnd;

  @override
  Widget build(BuildContext context) {
    final creationParams = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
    };

    if (Platform.isIOS) {
      return UiKitView(
        viewType: 'nekonata_map',
        onPlatformViewCreated: (id) {
          final controller = NekonataMapController._(
            id,
            onMarkerTapped: onMarkerTapped,
            onMapTapped: onMapTapped,
            onZoomEnd: onZoomEnd,
          );
          onControllerCreated?.call(controller);
        },
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
    return AndroidView(
      viewType: 'nekonata_map',
      onPlatformViewCreated: (id) {
        final controller = NekonataMapController._(
          id,
          onMarkerTapped: onMarkerTapped,
          onMapTapped: onMapTapped,
          onZoomEnd: onZoomEnd,
        );
        onControllerCreated?.call(controller);
      },
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}

/// A controller for a [NekonataMap]
///
/// The controller can not create manually,
/// this will be created by the [NekonataMap]
class NekonataMapController {
  NekonataMapController._(
    int id, {
    OnMarkerTapped? onMarkerTapped,
    OnMapTapped? onMapTapped,
    OnZoomEnd? onZoomEnd,
  }) : _channel = MethodChannel('nekonata_map_$id') {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
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
  Future<void> updateMarker({
    required String id,
    required double latitude,
    required double longitude,
  }) => _channel.invokeMethod('updateMarker', {
    'id': id,
    'latitude': latitude,
    'longitude': longitude,
  });

  /// Moves the camera to a specific location.
  Future<void> moveCamera({
    double? latitude,
    double? longitude,
    double? zoom,
    double? heading,
  }) => _channel.invokeMethod('moveCamera', {
    'latitude': latitude,
    'longitude': longitude,
    'zoom': zoom,
    'heading': heading,
  });
}
