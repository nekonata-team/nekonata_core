import 'package:flutter_test/flutter_test.dart';
import 'package:nekonata_map/nekonata_map.dart';
import 'package:nekonata_map/nekonata_map_platform_interface.dart';
import 'package:nekonata_map/nekonata_map_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNekonataMapPlatform
    with MockPlatformInterfaceMixin
    implements NekonataMapPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final NekonataMapPlatform initialPlatform = NekonataMapPlatform.instance;

  test('$MethodChannelNekonataMap is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNekonataMap>());
  });

  test('getPlatformVersion', () async {
    NekonataMap nekonataMapPlugin = NekonataMap();
    MockNekonataMapPlatform fakePlatform = MockNekonataMapPlatform();
    NekonataMapPlatform.instance = fakePlatform;

    expect(await nekonataMapPlugin.getPlatformVersion(), '42');
  });
}
