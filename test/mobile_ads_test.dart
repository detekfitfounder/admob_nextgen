import 'package:admob_nextgen/admob_nextgen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _channel = MethodChannel('next_gen_sdk');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  test('openAdInspector completes when inspector closes without error', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      expect(call.method, 'openAdInspector');
      return null;
    });

    await MobileAds.openAdInspector();
  });

  test('openAdInspector throws AdInspectorException on SDK error', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      return {
        'error': {'code': 2, 'message': 'Device is not in test mode'},
      };
    });

    await expectLater(
      MobileAds.openAdInspector(),
      throwsA(
        isA<AdInspectorException>()
            .having((e) => e.error.code, 'code', 2)
            .having(
              (e) => e.error.message,
              'message',
              'Device is not in test mode',
            ),
      ),
    );
  });
}
