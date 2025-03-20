import 'package:flutter_test/flutter_test.dart';
import 'package:nekonata_location_fetcher/model.dart';
import 'package:nekonata_location_fetcher/nekonata_location_fetcher.dart';
import 'package:nekonata_location_fetcher/nekonata_location_fetcher_method_channel.dart';
import 'package:nekonata_location_fetcher/nekonata_location_fetcher_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNekonataLocationFetcherPlatform
    with MockPlatformInterfaceMixin
    implements NekonataLocationFetcherPlatform {
  @override
  Future<void> start() {
    return Future.value();
  }

  @override
  Future<void> stop() {
    return Future.value();
  }

  @override
  Future<void> setCallback(void Function(Location location) callback) {
    return Future.value();
  }

  @override
  Future<bool> get isActivated async {
    return false;
  }

  @override
  Future<void> configure({
    bool? useCLServiceSession,
    String? notificationTitle,
    String? notificationText,
  }) {
    return Future.value();
  }
}

void main() {
  final initialPlatform = NekonataLocationFetcherPlatform.instance;

  test('$MethodChannelNekonataLocationFetcher is the default instance', () {
    expect(
      initialPlatform,
      isInstanceOf<MethodChannelNekonataLocationFetcher>(),
    );
  });

  test('example', () async {
    final nekonataLocationFetcherPlugin = NekonataLocationFetcher();
    final fakePlatform = MockNekonataLocationFetcherPlatform();
    NekonataLocationFetcherPlatform.instance = fakePlatform;

    expect(await nekonataLocationFetcherPlugin.isActivated, false);
  });
}
