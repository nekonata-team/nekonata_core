import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nekonata Map')),
      body: NekonataMap(
        latitude: 35.681236,
        longitude: 139.767125,
        onControllerCreated: (controller) => _controller = controller,
      ),
      persistentFooterButtons: [
        IconButton(
          onPressed: () async {
            final image = await rootBundle
                .load("assets/marker.png")
                .then((value) => value.buffer.asUint8List());
            _controller.addMarker(
              MarkerData(
                id: "1",
                latitude: 35.681236,
                longitude: 139.767125,
                image: image,
                minHeight: 40,
              ),
            );
          },
          icon: Icon(Icons.add),
        ),
        IconButton(
          onPressed: () {
            _controller.removeMarker("1");
          },
          icon: Icon(Icons.remove),
        ),
        IconButton(
          onPressed: () {
            final rnd = Random();
            final latDelta = 0.01 * (rnd.nextDouble() - 0.5);
            final lonDelta = 0.01 * (rnd.nextDouble() - 0.5);

            _controller.updateMarker(
              id: "1",
              latitude: 35.681236 + latDelta,
              longitude: 139.767125 + lonDelta,
            );
          },
          icon: Icon(Icons.update),
        ),
      ],
    );
  }
}
