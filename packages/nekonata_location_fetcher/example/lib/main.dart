import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nekonata_location_fetcher/model.dart';
import 'package:nekonata_location_fetcher/nekonata_location_fetcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
void _callback(Location location) {
  SharedPreferences.getInstance().then((prefs) {
    final locations = prefs.getStringList('locations') ?? [];
    locations.add(location.toString());
    if (locations.length > 100) {
      locations.removeRange(0, locations.length - 100);
    }
    prefs.setStringList('locations', locations);
    debugPrint('Location was updated');
  });
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final fetcher = NekonataLocationFetcher();

  @override
  void initState() {
    super.initState();
    fetcher.setCallback(_callback);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomePage(fetcher: fetcher));
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.fetcher});

  final NekonataLocationFetcher fetcher;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plugin example app')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FutureBuilder(
              future: fetcher.isActivated,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                final isActivated = snapshot.data;
                return Text('Activated: $isActivated');
              },
            ),
            if (Platform.isAndroid)
              ElevatedButton(
                onPressed: () async {
                  final status = await Permission.notification.request();
                  if (status.isGranted) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Permission granted')),
                      );
                    }
                  }
                },
                child: Text('Request Notification Permission'),
              ),
            ElevatedButton(
              onPressed: () async {
                final status = await Permission.location.request();
                final statusAlways = await Permission.locationAlways.request();

                if (status.isGranted && statusAlways.isGranted) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Permission granted')),
                    );
                  }
                }
              },
              child: const Text('Request Location Permission'),
            ),
            ElevatedButton(
              onPressed: () async {
                await fetcher.start();
              },
              child: const Text('Start'),
            ),
            ElevatedButton(
              onPressed: () async {
                await fetcher.stop();
              },
              child: const Text('Stop'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) {
                      return const LogPage();
                    },
                  ),
                );
              },
              child: const Text('Log'),
            ),
          ],
        ),
      ),
    );
  }
}

class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      prefs.reload();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log')),
      body: FutureBuilder<List<String>>(
        future: SharedPreferences.getInstance().then((prefs) {
          return prefs.getStringList('locations') ?? [];
        }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final locations = snapshot.data ?? [];
          return ListView.builder(
            itemCount: locations.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(locations[locations.length - index - 1]),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          SharedPreferences.getInstance().then((prefs) {
            prefs.setStringList('locations', []);
          });
        },
        child: const Icon(Icons.delete),
      ),
    );
  }
}
