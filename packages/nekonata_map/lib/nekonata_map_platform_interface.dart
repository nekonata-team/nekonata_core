import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'nekonata_map_method_channel.dart';

abstract class NekonataMapPlatform extends PlatformInterface {
  /// Constructs a NekonataMapPlatform.
  NekonataMapPlatform() : super(token: _token);

  static final Object _token = Object();

  static NekonataMapPlatform _instance = MethodChannelNekonataMap();

  /// The default instance of [NekonataMapPlatform] to use.
  ///
  /// Defaults to [MethodChannelNekonataMap].
  static NekonataMapPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NekonataMapPlatform] when
  /// they register themselves.
  static set instance(NekonataMapPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
