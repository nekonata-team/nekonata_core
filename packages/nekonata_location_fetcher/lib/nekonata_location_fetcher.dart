import 'package:nekonata_location_fetcher/model.dart';
import 'package:nekonata_location_fetcher/nekonata_location_fetcher_platform_interface.dart';

/// A base class for [NekonataLocationFetcher].
///
/// To mock the service, replace the instance of [NekonataLocationFetcherPlatform].
class NekonataLocationFetcher extends NekonataLocationFetcherPlatform {
  NekonataLocationFetcherPlatform get _platform =>
      NekonataLocationFetcherPlatform.instance;

  @override
  Future<void> start() => _platform.start();

  @override
  Future<void> stop() => _platform.stop();

  @override
  Future<void> setCallback(void Function(Location location) callback) =>
      _platform.setCallback(callback);

  @override
  Future<bool> get isActivated async => _platform.isActivated;

  @override
  Future<void> setAndroidNotification({
    required String? title,
    required String? text,
  }) => _platform.setAndroidNotification(title: title, text: text);
}
