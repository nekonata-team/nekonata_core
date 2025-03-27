import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nekonata_location_fetcher/model/configuration.dart';
import 'package:nekonata_location_fetcher/model/location.dart';
import 'package:nekonata_location_fetcher/nekonata_location_fetcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'main.g.dart';

const _locationKey = 'locations';
final _prefs = SharedPreferencesAsync();

@pragma('vm:entry-point')
Future<void> _callback(Location location) async {
  final locations = await _prefs.getStringList(_locationKey) ?? [];
  locations.add(location.toString());
  if (locations.length > 100) {
    locations.removeRange(0, locations.length - 100);
  }
  await _prefs.setStringList(_locationKey, locations);
  debugPrint('Location was updated');
}

@riverpod
NekonataLocationFetcher _locationFetcher(Ref ref) {
  return NekonataLocationFetcher();
}

@riverpod
Future<bool> _suppressBackgroundLocationAccess(Ref ref) async {
  final fetcher = ref.watch(_locationFetcherProvider);
  final config = await fetcher.configuration;
  final background = config.useBackgroundActivitySessionManager ?? true;
  final mode = config.mode;

  return mode == Mode.locationManager && !background;
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomePage());
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fetcher = ref.watch(_locationFetcherProvider);

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
                await fetcher.setCallback(_callback);
                await fetcher.configure(
                  distanceFilter: 10,
                  interval: 5,
                  notificationTitle: 'Nekonata Location Fetcher',
                  notificationText:
                      'Fetching location data. This is customized text.',
                );
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
              onPressed: () async {
                final config = await fetcher.configuration;

                if (!context.mounted) return;

                showDialog(
                  context: context,
                  builder: (_) {
                    return ConfigurationDialog(config: config);
                  },
                );
              },
              child: const Text('Get Configuration'),
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
            if (Platform.isIOS)
              const SuppressBackgroundLocationAccessSwitchListTile(),
          ],
        ),
      ),
    );
  }
}

class ConfigurationDialog extends StatelessWidget {
  const ConfigurationDialog({super.key, required this.config});

  final Configuration config;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configuration'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Distance Filter'),
            subtitle: Text(config.distanceFilter.toString()),
          ),
          ListTile(
            title: const Text('Interval'),
            subtitle: Text(config.interval.toString()),
          ),
          ListTile(
            title: const Text('Mode'),
            subtitle: Text(config.mode.toString()),
          ),
          ListTile(
            title: const Text('Use Background Activity Session Manager'),
            subtitle: Text(
              config.useBackgroundActivitySessionManager.toString(),
            ),
          ),
          ListTile(
            title: const Text('Notification Title'),
            subtitle: Text(config.notificationTitle.toString()),
          ),
          ListTile(
            title: const Text('Notification Text'),
            subtitle: Text(config.notificationText.toString()),
          ),
        ],
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
        future: _prefs.getStringList(_locationKey).then((value) => value ?? []),
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
        onPressed: () async {
          await _prefs.setStringList(_locationKey, []);
        },
        child: const Icon(Icons.delete),
      ),
    );
  }
}

class SuppressBackgroundLocationAccessSwitchListTile extends ConsumerWidget {
  const SuppressBackgroundLocationAccessSwitchListTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwitchListTile(
      title: Text("Suppress Background Location Access"),
      secondary: const Icon(Icons.my_location_outlined),
      onChanged: (value) async {
        await _switch(value, ref);
      },
      value:
          ref.watch(_suppressBackgroundLocationAccessProvider).value ?? false,
    );
  }

  Future<void> _switch(bool suppress, WidgetRef ref) async {
    // 基本的に、useBackgroundActivitySessionManagerと
    // useCLLocationUpdateは高精度になるので逆の値を指定する
    final fetcher = ref.read(_locationFetcherProvider);

    await fetcher.configure(
      useBackgroundActivitySessionManager: !suppress,
      mode: suppress ? Mode.locationManager : Mode.hybrid,
    );
    ref.invalidate(_suppressBackgroundLocationAccessProvider);
  }
}
