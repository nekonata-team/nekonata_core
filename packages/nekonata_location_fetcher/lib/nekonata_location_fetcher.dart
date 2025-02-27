import 'package:nekonata_location_fetcher/model.dart';
import 'package:nekonata_location_fetcher/nekonata_location_fetcher_platform_interface.dart';

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
}
