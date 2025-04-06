import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';
import 'package:nekonata_map/marker.dart';

/// Callback typedef that will be called when a marker is tapped.
typedef OnMarkerTapped = void Function(String id);

/// Callback typedef that will be called when the map is tapped.
typedef OnMapTapped = void Function(double latitude, double longitude);

/// Callback typedef that will be called when the zoom level of the map changes.
typedef OnZoomEnd = void Function(double zoom);

/// Callback typedef that will be called when a controller is created.
typedef OnControllerCreated = void Function(NekonataMapController controller);

/// Callback typedef that will be called when the camera moves.
typedef OnCameraMove = void Function();

/// A widget that displays a map.
class NekonataMap extends StatelessWidget {
  /// Creates a new [NekonataMap] instance.
  const NekonataMap({
    super.key,
    this.latLng,
    this.onControllerCreated,
    this.onMarkerTapped,
    this.onMapTapped,
    this.onZoomEnd,
    this.onCameraMove,
  });

  /// The initial latitude and longitude of the map.
  final LatLng? latLng;

  /// Callback that will be called when a controller is created.
  final OnControllerCreated? onControllerCreated;

  /// Callback that will be called when a marker is tapped.
  final OnMarkerTapped? onMarkerTapped;

  /// Callback that will be called when the map is tapped.
  final OnMapTapped? onMapTapped;

  /// Callback that will be called when the zoom level of the map changes.
  final OnZoomEnd? onZoomEnd;

  /// Callback that will be called when the camera moves.
  final OnCameraMove? onCameraMove;

  @override
  Widget build(BuildContext context) {
    final creationParams = {
      'latitude': latLng?.latitude,
      'longitude': latLng?.longitude,
    };

    if (Platform.isIOS) {
      return UiKitView(
        viewType: 'nekonata_map',
        onPlatformViewCreated: (id) {
          NekonataMapController._(
            id,
            onControllerCreated: onControllerCreated,
            onMarkerTapped: onMarkerTapped,
            onMapTapped: onMapTapped,
            onZoomEnd: onZoomEnd,
            onCameraMove: onCameraMove,
          );
        },
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
    return AndroidView(
      viewType: 'nekonata_map',
      onPlatformViewCreated: (id) {
        NekonataMapController._(
          id,
          onControllerCreated: onControllerCreated,
          onMarkerTapped: onMarkerTapped,
          onMapTapped: onMapTapped,
          onZoomEnd: onZoomEnd,
          onCameraMove: onCameraMove,
        );
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
  /// Creates a new [NekonataMapController] instance.
  /// This constructor is used internally by the [NekonataMap].
  NekonataMapController._(
    int id, {
    OnControllerCreated? onControllerCreated,
    OnMarkerTapped? onMarkerTapped,
    OnMapTapped? onMapTapped,
    OnZoomEnd? onZoomEnd,
    OnCameraMove? onCameraMove,
  }) : _channel = MethodChannel('nekonata_map_$id') {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onCameraMove':
          onCameraMove?.call();
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

  /// Gets the current latitude and longitude of the map.
  Future<LatLng> get latLng =>
      _channel.invokeMethod<Map<dynamic, dynamic>>('latLng').then((value) {
        final latitude = value!['latitude'] as double;
        final longitude = value['longitude'] as double;
        return LatLng(latitude, longitude);
      });

  /// Gets the current heading of the map.
  Future<double> get heading =>
      _channel.invokeMethod<double>('heading').then((value) => value!);

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
