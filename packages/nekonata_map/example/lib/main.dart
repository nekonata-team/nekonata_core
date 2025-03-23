import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:nekonata_map/marker.dart';
import 'package:nekonata_map/nekonata_map.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const MapPage());
  }
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late final NekonataMapController _controller;
  var isVisible = true;
  final rnd = Random();

  Future<void> _addMarkers() async {
    final png = await rootBundle
        .load("assets/marker.png")
        .then((value) => value.buffer.asUint8List());

    final gif = await rootBundle
        .load("assets/marker.gif")
        .then((value) => value.buffer.asUint8List());

    _controller.addMarker(
      MarkerData(id: "1", latLng: LatLng(35.68, 139.767125)),
    );
    _controller.addMarker(
      MarkerData(
        id: "2",
        latLng: LatLng(35.681236, 139.767125),
        image: png,
        minHeight: 40,
        minWidth: 40,
      ),
    );
    _controller.addMarker(
      MarkerData(
        id: "3",
        latLng: LatLng(35.682, 139.767125),
        image: gif,
        minHeight: 64,
        minWidth: 64,
      ),
    );
  }

  Future<void> _clearMarkers() async {
    await _controller.removeMarker("1");
    await _controller.removeMarker("2");
    await _controller.removeMarker("3");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nekonata Map')),
      body: NekonataMap(
        latLng: const LatLng(35.681236, 139.767125),
        onControllerCreated: (controller) {
          _controller = controller;
          _addMarkers();
        },
        onMarkerTapped: (id) => debugPrint("Marker tapped: $id"),
        onMapTapped:
            (latitude, longitude) =>
                debugPrint("Map tapped: $latitude, $longitude"),
        onZoomEnd: (zoom) => debugPrint("Zoom end: $zoom"),
      ),
      persistentFooterButtons: [
        IconButton(
          onPressed: () async {
            await _clearMarkers();
            await _addMarkers();
          },
          icon: Icon(Icons.refresh),
        ),
        IconButton(
          onPressed: () {
            final latDelta = 0.01 * (rnd.nextDouble() - 0.5);
            final lonDelta = 0.01 * (rnd.nextDouble() - 0.5);

            _controller.updateMarker(
              "1",
              LatLng(35.681236 + latDelta, 139.767125 + lonDelta),
            );
          },
          icon: Icon(Icons.update),
        ),
        IconButton(
          onPressed: () {
            final latDelta = 0.01 * (rnd.nextDouble() - 0.5);
            final lonDelta = 0.01 * (rnd.nextDouble() - 0.5);
            final zoom = rnd.nextDouble() * 18;
            final heading = rnd.nextDouble() * 360;

            _controller.moveCamera(
              latLng: LatLng(35.681236 + latDelta, 139.767125 + lonDelta),
              zoom: zoom,
              heading: heading,
            );
          },
          icon: Icon(Icons.camera),
        ),
        IconButton(
          onPressed: () {
            setState(() => isVisible = !isVisible);
            _controller.setMarkerVisible("1", isVisible: isVisible);
            _controller.setMarkerVisible("2", isVisible: isVisible);
            _controller.setMarkerVisible("3", isVisible: isVisible);
          },
          icon: Icon(Icons.opacity),
        ),
        IconButton(
          onPressed: () async {
            final zoom = await _controller.zoom;
            _controller.moveCamera(zoom: zoom + 1);
          },
          icon: Icon(Icons.zoom_in),
        ),
        IconButton(
          onPressed: () async {
            final zoom = await _controller.zoom;
            _controller.moveCamera(zoom: zoom - 1);
          },
          icon: Icon(Icons.zoom_out),
        ),
      ],
    );
  }
}
