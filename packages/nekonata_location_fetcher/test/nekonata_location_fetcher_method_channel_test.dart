import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nekonata_location_fetcher/nekonata_location_fetcher_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelNekonataLocationFetcher();
  const channel = MethodChannel('nekonata_location_fetcher');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return switch (methodCall.method) {
            'start' => null,
            'stop' => null,
            'setCallback' => null,
            'setAndroidNotification' => null,
            'isActivated' => false,
            _ => throw UnimplementedError(),
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('example', () async {
    expect(await platform.isActivated, false);
  });
}
