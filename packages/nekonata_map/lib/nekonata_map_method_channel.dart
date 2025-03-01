import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'nekonata_map_platform_interface.dart';

/// An implementation of [NekonataMapPlatform] that uses method channels.
class MethodChannelNekonataMap extends NekonataMapPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('nekonata_map');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
