import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:nekonata_map/gestures/edge_zoom_gesture.dart';
import 'package:nekonata_map/marker.dart';
import 'package:nekonata_map/nekonata_map.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: MapPage());
  }
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  NekonataMapController? _controller;
  bool isVisible = true;
  final Random _random = Random();

  Future<void> _addMarkers(NekonataMapController controller) async {
    final png = await rootBundle
        .load("assets/marker.png")
        .then((value) => value.buffer.asUint8List());

    final gif = await rootBundle
        .load("assets/marker.gif")
        .then((value) => value.buffer.asUint8List());

    controller.addMarker(
      MarkerData(id: "1", latLng: LatLng(35.68, 139.767125)),
    );
    controller.addMarker(
      MarkerData(
        id: "2",
        latLng: LatLng(35.681236, 139.767125),
        image: png,
        minHeight: 40,
        minWidth: 40,
      ),
    );
    controller.addMarker(
      MarkerData(
        id: "3",
        latLng: LatLng(35.682, 139.767125),
        image: gif,
        minHeight: 64,
        minWidth: 64,
      ),
    );
  }

  Future<void> _clearMarkers(NekonataMapController controller) async {
    for (final id in ["1", "2", "3"]) {
      await controller.removeMarker(id);
    }
  }

  void _toggleMarkerVisibility(NekonataMapController controller) {
    setState(() => isVisible = !isVisible);
    for (final id in ["1", "2", "3"]) {
      controller.setMarkerVisible(id, isVisible: isVisible);
    }
  }

  void _updateMarkerPosition(NekonataMapController controller) {
    final latDelta = 0.01 * (_random.nextDouble() - 0.5);
    final lonDelta = 0.01 * (_random.nextDouble() - 0.5);

    controller.updateMarker(
      "1",
      LatLng(35.681236 + latDelta, 139.767125 + lonDelta),
    );
  }

  void _moveCameraRandomly(NekonataMapController controller) {
    final latDelta = 0.01 * (_random.nextDouble() - 0.5);
    final lonDelta = 0.01 * (_random.nextDouble() - 0.5);
    final zoom = _random.nextDouble() * 18;
    final heading = _random.nextDouble() * 360;

    controller.moveCamera(
      latLng: LatLng(35.681236 + latDelta, 139.767125 + lonDelta),
      zoom: zoom,
      heading: heading,
    );
  }

  Future<void> _zoomIn(NekonataMapController controller) async {
    final zoom = await controller.zoom;
    controller.moveCamera(zoom: zoom + 1);
  }

  Future<void> _zoomOut(NekonataMapController controller) async {
    final zoom = await controller.zoom;
    controller.moveCamera(zoom: zoom - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          NekonataMap(
            latLng: const LatLng(35.681236, 139.767125),
            onControllerCreated: (controller) {
              setState(() => _controller = controller);
              _addMarkers(controller);
            },
            onMarkerTapped: (id) => debugPrint("Marker tapped: $id"),
            onMapTapped:
                (latitude, longitude) =>
                    debugPrint("Map tapped: $latitude, $longitude"),
            onZoomEnd: (zoom) => debugPrint("Zoom end: $zoom"),
          ),
          if (_controller != null) EdgeZoomGesture(controller: _controller!),
        ],
      ),
      persistentFooterButtons: [
        if (_controller != null) ..._buildFooterButtons(_controller!),
      ],
    );
  }

  List<Widget> _buildFooterButtons(NekonataMapController controller) {
    return [
      IconButton(
        onPressed: () async {
          await _clearMarkers(controller);
          await _addMarkers(controller);
        },
        icon: const Icon(Icons.refresh),
      ),
      IconButton(
        onPressed: () => _updateMarkerPosition(controller),
        icon: const Icon(Icons.update),
      ),
      IconButton(
        onPressed: () => _moveCameraRandomly(controller),
        icon: const Icon(Icons.camera),
      ),
      IconButton(
        onPressed: () => _toggleMarkerVisibility(controller),
        icon: const Icon(Icons.opacity),
      ),
      IconButton(
        onPressed: () => _zoomIn(controller),
        icon: const Icon(Icons.zoom_in),
      ),
      IconButton(
        onPressed: () => _zoomOut(controller),
        icon: const Icon(Icons.zoom_out),
      ),
    ];
  }
}
