import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:nekonata_map/marker.dart';

/// Callback typedef that will be called when a marker is selected.
typedef OnMarkerSelected = void Function(String id);

/// Callback typedef that will be called when a controller is created.
typedef OnControllerCreated = void Function(NekonataMapController controller);

/// A widget that displays a map.
class NekonataMap extends StatefulWidget {
  /// Creates a new [NekonataMap] instance.
  const NekonataMap({
    super.key,
    this.latitude,
    this.longitude,
    this.onControllerCreated,
    this.onMarkerSelected,
  });

  /// The initial latitude of the map.
  final double? latitude;

  /// The initial longitude of the map.
  final double? longitude;

  /// Callback that will be called when a controller is created.
  final OnControllerCreated? onControllerCreated;

  /// Callback that will be called when a marker is selected.
  final OnMarkerSelected? onMarkerSelected;

  @override
  State<NekonataMap> createState() => _NekonataMapState();
}

class _NekonataMapState extends State<NekonataMap> {
  NekonataMapController? controller;
  @override
  Widget build(BuildContext context) {
    final creationParams = <String, dynamic>{
      'latitude': widget.latitude,
      'longitude': widget.longitude,
    };

    if (Platform.isIOS) {
      return UiKitView(
        viewType: 'nekonata_map',
        onPlatformViewCreated: (id) {
          setState(() {
            controller = NekonataMapController._(
              id,
              onMarkerSelected: widget.onMarkerSelected,
            );
            widget.onControllerCreated?.call(controller!);
          });
        },
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
    return AndroidView(
      viewType: 'nekonata_map',
      onPlatformViewCreated: (id) {
        setState(() {
          controller = NekonataMapController._(
            id,
            onMarkerSelected: widget.onMarkerSelected,
          );
          widget.onControllerCreated?.call(controller!);
        });
      },
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}

/// A controller for a [NekonataMap] widget.
///
/// The controller can not create manually,
/// this will be created by the [NekonataMap] widget.
class NekonataMapController {
  NekonataMapController._(int id, {OnMarkerSelected? onMarkerSelected})
    : _onMarkerSelected = onMarkerSelected,
      _channel = MethodChannel('nekonata_map_$id') {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onSelected':
          _onMarkerSelected?.call(call.arguments as String);
        default:
          throw MissingPluginException(call.method);
      }
    });
  }

  final MethodChannel _channel;
  final OnMarkerSelected? _onMarkerSelected;

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
