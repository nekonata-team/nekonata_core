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
  Future<void> configure({
    double? distanceFilter,
    int? interval,
    bool? useCLServiceSession,
    String? notificationTitle,
    String? notificationText,
  }) => _platform.configure(
    distanceFilter: distanceFilter,
    interval: interval,
    useCLServiceSession: useCLServiceSession,
    notificationTitle: notificationTitle,
    notificationText: notificationText,
  );
}
