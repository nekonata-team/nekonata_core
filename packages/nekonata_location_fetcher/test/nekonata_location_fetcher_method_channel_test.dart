import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nekonata_location_fetcher/nekonata_location_fetcher_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelNekonataLocationFetcher platform = MethodChannelNekonataLocationFetcher();
  const MethodChannel channel = MethodChannel('nekonata_location_fetcher');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
