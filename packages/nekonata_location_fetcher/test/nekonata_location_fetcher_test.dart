import 'package:flutter_test/flutter_test.dart';
import 'package:nekonata_location_fetcher/nekonata_location_fetcher.dart';
import 'package:nekonata_location_fetcher/nekonata_location_fetcher_platform_interface.dart';
import 'package:nekonata_location_fetcher/nekonata_location_fetcher_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNekonataLocationFetcherPlatform
    with MockPlatformInterfaceMixin
    implements NekonataLocationFetcherPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final NekonataLocationFetcherPlatform initialPlatform = NekonataLocationFetcherPlatform.instance;

  test('$MethodChannelNekonataLocationFetcher is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNekonataLocationFetcher>());
  });

  test('getPlatformVersion', () async {
    NekonataLocationFetcher nekonataLocationFetcherPlugin = NekonataLocationFetcher();
    MockNekonataLocationFetcherPlatform fakePlatform = MockNekonataLocationFetcherPlatform();
    NekonataLocationFetcherPlatform.instance = fakePlatform;

    expect(await nekonataLocationFetcherPlugin.getPlatformVersion(), '42');
  });
}
