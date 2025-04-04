import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';
import 'package:nekonata_map/nekonata_map_controller.dart';

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
    this.latLng,
    this.onControllerCreated,
    this.onMarkerTapped,
    this.onMapTapped,
    this.onZoomEnd,
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
          NekonataMapController.internal(
            id,
            onControllerCreated: onControllerCreated,
            onMarkerTapped: onMarkerTapped,
            onMapTapped: onMapTapped,
            onZoomEnd: onZoomEnd,
          );
        },
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
    return AndroidView(
      viewType: 'nekonata_map',
      onPlatformViewCreated: (id) {
        NekonataMapController.internal(
          id,
          onControllerCreated: onControllerCreated,
          onMarkerTapped: onMarkerTapped,
          onMapTapped: onMapTapped,
          onZoomEnd: onZoomEnd,
        );
      },
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}
