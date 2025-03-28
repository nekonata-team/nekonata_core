import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nekonata_location_fetcher/model/configuration.dart';
import 'package:nekonata_location_fetcher/model/location.dart';
import 'package:nekonata_location_fetcher/nekonata_location_fetcher_platform_interface.dart';

class _Keys {
  const _Keys._();

  static const callback = 'callback';
  static const distanceFilter = 'distanceFilter';
  static const interval = 'interval';

  // iOS only
  static const mode = 'mode';
  static const useBackgroundActivitySessionManager =
      'useBackgroundActivitySessionManager';

  // Android only
  static const notificationTitle = 'notificationTitle';
  static const notificationText = 'notificationText';
  static const dispatcherRawHandle = 'dispatcherRawHandle';
  static const rawHandle = 'rawHandle';
}

/// Android can be separate engine, so we need to use a callback dispatcher.
@pragma('vm:entry-point')
void _androidCallback() {
  WidgetsFlutterBinding.ensureInitialized(); // For calling setMethodCallHandler
  debugPrint('🐱 Dispatcher was called');
  const MethodChannel(
    'nekonata_location_fetcher',
  ).setMethodCallHandler(_androidHandler);
}

Future<dynamic> _androidHandler(MethodCall call) async {
  switch (call.method) {
    case _Keys.callback:
      final json = call.arguments as Map<dynamic, dynamic>;
      final handle = json[_Keys.rawHandle] as int;
      final location = Location.fromJson(json);

      final callback = PluginUtilities.getCallbackFromHandle(
        CallbackHandle.fromRawHandle(handle),
      );
      if (callback is void Function(Location)) {
        callback(location);
      }
  }
}

/// An implementation of [NekonataLocationFetcherPlatform] that uses method channels.
class MethodChannelNekonataLocationFetcher
    extends NekonataLocationFetcherPlatform {
  /// Constructs a [MethodChannelNekonataLocationFetcher].
  MethodChannelNekonataLocationFetcher() {
    if (Platform.isIOS) {
      methodChannel.setMethodCallHandler(_iOSHandler);
    }
  }
  void Function(Location) _iOSCallback = (_) {};

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('nekonata_location_fetcher');

  /// iOS will be launched main even if the app is in background.
  /// That's because application:didFinishLaunchingWithOptions is called.
  /// So we don't need to use a callback dispatcher.
  Future<dynamic> _iOSHandler(MethodCall call) async {
    switch (call.method) {
      case _Keys.callback:
        final json = call.arguments as Map<dynamic, dynamic>;
        final location = Location.fromJson(json);
        _iOSCallback(location);
    }
  }

  @override
  Future<void> start() async {
    await methodChannel.invokeMethod<void>('start');
  }

  @override
  Future<void> stop() async {
    await methodChannel.invokeMethod<void>('stop');
  }

  @override
  Future<void> setCallback(void Function(Location location) callback) async {
    if (Platform.isAndroid) {
      final dispatcherHandle = PluginUtilities.getCallbackHandle(
        _androidCallback,
      );
      final handle = PluginUtilities.getCallbackHandle(callback);
      assert(
        handle != null,
        'The callback must be a top-level or static function.',
      );

      await methodChannel.invokeMethod<void>('setCallback', {
        _Keys.dispatcherRawHandle: dispatcherHandle!.toRawHandle(),
        _Keys.rawHandle: handle!.toRawHandle(),
      });
    } else {
      _iOSCallback = callback;
    }
  }

  @override
  Future<bool> get isActivated async {
    return await methodChannel.invokeMethod<bool>('isActivated') ?? false;
  }

  @override
  Future<Configuration> get configuration async {
    final json = await methodChannel.invokeMethod<Map<dynamic, dynamic>>(
      'configuration',
    );
    return Configuration.fromJson(json!);
  }

  @override
  Future<void> configure({
    double? distanceFilter,
    int? interval,
    Mode? mode,
    bool? useBackgroundActivitySessionManager,
    String? notificationTitle,
    String? notificationText,
  }) async {
    await methodChannel.invokeMethod<void>('configure', {
      _Keys.distanceFilter: distanceFilter,
      _Keys.interval: interval,
      _Keys.mode: mode?.name,
      _Keys.useBackgroundActivitySessionManager:
          useBackgroundActivitySessionManager,
      _Keys.notificationTitle: notificationTitle,
      _Keys.notificationText: notificationText,
    });
  }
}
