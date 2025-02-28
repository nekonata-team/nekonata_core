import 'package:nekonata_location_fetcher/model.dart';
import 'package:nekonata_location_fetcher/nekonata_location_fetcher_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class NekonataLocationFetcherPlatform extends PlatformInterface {
  /// Constructs a NekonataLocationFetcherPlatform.
  NekonataLocationFetcherPlatform() : super(token: _token);

  static final Object _token = Object();

  static NekonataLocationFetcherPlatform _instance =
      MethodChannelNekonataLocationFetcher();

  /// The default instance of [NekonataLocationFetcherPlatform] to use.
  ///
  /// Defaults to [MethodChannelNekonataLocationFetcher].
  static NekonataLocationFetcherPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NekonataLocationFetcherPlatform] when
  /// they register themselves.
  static set instance(NekonataLocationFetcherPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> start() async {
    throw UnimplementedError('start() has not been implemented.');
  }

  Future<void> stop() async {
    throw UnimplementedError('stop() has not been implemented.');
  }

  Future<void> setCallback(void Function(Location location) callback) async {
    throw UnimplementedError('setCallback() has not been implemented.');
  }

  Future<bool> get isActivated async {
    throw UnimplementedError('isStarted has not been implemented.');
  }
}
