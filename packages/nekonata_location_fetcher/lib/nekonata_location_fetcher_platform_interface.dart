import 'package:nekonata_location_fetcher/model/configuration.dart';
import 'package:nekonata_location_fetcher/model/location.dart';
import 'package:nekonata_location_fetcher/nekonata_location_fetcher_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The interface of `nekonata_location_fetcher`.
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

  /// Starts fetching location data.
  ///
  /// Location service is monotonic,
  /// so calling this method multiple times will not have any effect.
  Future<void> start() async {
    throw UnimplementedError('start() has not been implemented.');
  }

  /// Stops fetching location data.
  Future<void> stop() async {
    throw UnimplementedError('stop() has not been implemented.');
  }

  /// Sets a callback that will be called when a new location is fetched.
  ///
  /// Callback must be a top-level and **@pragma('vm:entry-point')** function.
  Future<void> setCallback(void Function(Location location) callback) async {
    throw UnimplementedError('setCallback() has not been implemented.');
  }

  /// Returns whether the location fetcher is activated.
  Future<bool> get isActivated async {
    throw UnimplementedError('isActivated has not been implemented.');
  }

  /// Returns the current configuration.
  Future<Configuration> get configuration async {
    throw UnimplementedError('configuration has not been implemented.');
  }

  /// Configures the location fetcher.
  ///
  /// If you call this, Automatically, the location fetcher will be restarted.
  /// These values will be stored permanently.
  /// If set to `null`, the value will not be changed.
  /// - [distanceFilter]: The minimum distance between location updates in meters.
  /// - [interval]: The minimum time between location updates in seconds.
  /// - [mode]: IOS Model name. See README for details.
  /// - [useBackgroundActivitySessionManager]: IOS Whether to use BackgroundActivitySessionManager. This is for iOS 17.0.
  /// - [notificationTitle]: ANDROID The title of the notification.
  /// - [notificationText]: ANDROID The text of the notification.
  Future<void> configure({
    double? distanceFilter,
    int? interval,
    Mode? mode,
    bool? useBackgroundActivitySessionManager,
    String? notificationTitle,
    String? notificationText,
  }) async {
    throw UnimplementedError('configure() has not been implemented.');
  }
}
