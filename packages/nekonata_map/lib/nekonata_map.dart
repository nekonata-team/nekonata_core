import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:nekonata_map/marker.dart';

typedef OnMarkerSelected = void Function(String id);

class NekonataMap extends StatefulWidget {
  const NekonataMap({
    super.key,
    this.latitude,
    this.longitude,
    this.onControllerCreated,
    this.onMarkerSelected,
  });

  final double? latitude;
  final double? longitude;
  final void Function(NekonataMapController controller)? onControllerCreated;
  final OnMarkerSelected? onMarkerSelected;

  @override
  State<NekonataMap> createState() => _NekonataMapState();
}

class _NekonataMapState extends State<NekonataMap> {
  NekonataMapController? controller;
  @override
  Widget build(BuildContext context) {
    final creationParams = <String, dynamic>{
      "latitude": widget.latitude,
      "longitude": widget.longitude,
    };

    if (Platform.isIOS) {
      return UiKitView(
        viewType: 'nekonata_map',
        onPlatformViewCreated: (id) {
          setState(() {
            controller = NekonataMapController(
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
          controller = NekonataMapController(
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

class NekonataMapController {
  NekonataMapController(int id, {required this.onMarkerSelected})
    : channel = MethodChannel('nekonata_map_$id') {
    channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case "onSelected":
          onMarkerSelected?.call(call.arguments);
        default:
          throw MissingPluginException(call.method);
      }
    });
  }

  final MethodChannel channel;
  final OnMarkerSelected? onMarkerSelected;

  void addMarker(MarkerData marker) {
    channel.invokeMethod('addMarker', marker.toMap());
  }

  void removeMarker(String id) {
    channel.invokeMethod('removeMarker', id);
  }

  void updateMarker({
    required String id,
    required double latitude,
    required double longitude,
  }) {
    channel.invokeMethod('updateMarker', {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  void moveCamera({
    double? latitude,
    double? longitude,
    double? zoom,
    double? heading,
  }) {
    channel.invokeMethod('moveCamera', {
      'latitude': latitude,
      'longitude': longitude,
      'zoom': zoom,
      'heading': heading,
    });
  }
}
