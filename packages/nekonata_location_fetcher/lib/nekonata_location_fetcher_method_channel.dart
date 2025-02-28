import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nekonata_location_fetcher/model.dart';
import 'package:nekonata_location_fetcher/nekonata_location_fetcher_platform_interface.dart';

@pragma('vm:entry-point')
void _callback() {
  debugPrint('Despatcher was called');
  WidgetsFlutterBinding.ensureInitialized();
  const MethodChannel('nekonata_location_fetcher').setMethodCallHandler((
    call,
  ) async {
    switch (call.method) {
      case 'callback':
        final json = call.arguments as Map<dynamic, dynamic>;
        final handle = json['rawHandle'] as int;
        final location = Location.fromJson(json);

        final callback = PluginUtilities.getCallbackFromHandle(
          CallbackHandle.fromRawHandle(handle),
        );
        if (callback is void Function(Location)) {
          callback(location);
        }
    }
  });
}

/// An implementation of [NekonataLocationFetcherPlatform] that uses method channels.
class MethodChannelNekonataLocationFetcher
    extends NekonataLocationFetcherPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('nekonata_location_fetcher');

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
    final dispatcherHandle = PluginUtilities.getCallbackHandle(_callback);
    final handle = PluginUtilities.getCallbackHandle(callback);
    assert(
      handle != null,
      'The callback must be a top-level or static function.',
    );

    await methodChannel.invokeMethod<void>('setCallback', {
      'dispatcherRawHandle': dispatcherHandle!.toRawHandle(),
      'rawHandle': handle!.toRawHandle(),
    });
  }

  @override
  Future<bool> get isActivated async {
    return await methodChannel.invokeMethod<bool>('isActivated') ?? false;
  }

  @override
  Future<void> setAndroidNotification({
    required String? title,
    required String? text,
  }) async {
    await methodChannel.invokeMethod<void>('setAndroidNotification', {
      'title': title,
      'text': text,
    });
  }
}
