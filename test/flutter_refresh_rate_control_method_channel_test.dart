import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_refresh_rate_control/flutter_refresh_rate_control_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelFlutterRefreshRateControl platform =
      MethodChannelFlutterRefreshRateControl();
  const MethodChannel channel = MethodChannel(
    'com.zeyus.flutter_refresh_rate_control/manage',
  );

  final List<MethodCall> calls = [];

  void mockNativePlugin() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          calls.add(methodCall);
          switch (methodCall.method) {
            case 'getPlatformVersion':
              return '42';
            case 'requestHighRefreshRate':
              return true;
            case 'stopHighRefreshRate':
              return true;
            case 'getRefreshRateInfo':
              return {
                'maximumFramesPerSecond': 120,
                'currentRefreshRate': 60.0,
                'highRefreshRateEnabled': false,
              };
            default:
              return null;
          }
        });
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    platform.setExceptionOnUnsupportedPlatform(false);
    debugDefaultTargetPlatformOverride = null;
    calls.clear();
  });

  test('exceptionOnUnsupportedPlatform setter', () {
    expect(platform.exceptionOnUnsupportedPlatform, false);
    platform.setExceptionOnUnsupportedPlatform(true);
    expect(platform.exceptionOnUnsupportedPlatform, true);
    platform.setExceptionOnUnsupportedPlatform(false);
    expect(platform.exceptionOnUnsupportedPlatform, false);
  });

  for (final supported in [
    TargetPlatform.android,
    TargetPlatform.iOS,
    TargetPlatform.macOS,
  ]) {
    group('supported platform $supported', () {
      setUp(() {
        debugDefaultTargetPlatformOverride = supported;
        mockNativePlugin();
      });

      test('getPlatformVersion', () async {
        expect(await platform.getPlatformVersion(), '42');
      });

      test('requestHighRefreshRate', () async {
        expect(await platform.requestHighRefreshRate(), true);
      });

      test('stopHighRefreshRate', () async {
        expect(await platform.stopHighRefreshRate(), true);
        expect(calls.single.arguments, {'force': false});
      });

      test('stopHighRefreshRate with force', () async {
        expect(await platform.stopHighRefreshRate(force: true), true);
        expect(calls.single.arguments, {'force': true});
      });

      test('getRefreshRateInfo', () async {
        final info = await platform.getRefreshRateInfo();
        expect(info['platform'], supported.name.toLowerCase());
        expect(info['supported'], true);
        expect(info['maximumFramesPerSecond'], 120);
        expect(info['currentRefreshRate'], 60.0);
        expect(info['currentFramesPerSecond'], 60.0);
        expect(info['highRefreshRateEnabled'], false);
      });

      test('does not throw with exceptions enabled', () async {
        platform.setExceptionOnUnsupportedPlatform(true);
        expect(await platform.requestHighRefreshRate(), true);
      });
    });
  }

  group('supported platform without the native plugin registered', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
    });

    test('methods fall back to no-op results', () async {
      expect(await platform.getPlatformVersion(), isNull);
      expect(await platform.requestHighRefreshRate(), false);
      expect(await platform.stopHighRefreshRate(), false);
      expect(await platform.stopHighRefreshRate(force: true), false);
      expect(await platform.getRefreshRateInfo(), {
        'platform': 'android',
        'supported': true,
      });
    });

    test('methods throw with exceptions enabled', () async {
      platform.setExceptionOnUnsupportedPlatform(true);
      await expectLater(
        platform.requestHighRefreshRate(),
        throwsA(isA<MissingPluginException>()),
      );
    });
  });

  for (final unsupported in [
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.fuchsia,
  ]) {
    group('unsupported platform $unsupported', () {
      setUp(() {
        debugDefaultTargetPlatformOverride = unsupported;
        // Must never be reached on an unsupported platform
        mockNativePlugin();
      });

      test('getPlatformVersion', () async {
        expect(
          await platform.getPlatformVersion(),
          'Unsupported platform: ${unsupported.name.toLowerCase()}',
        );
      });

      test('requestHighRefreshRate', () async {
        expect(await platform.requestHighRefreshRate(), false);
      });

      test('stopHighRefreshRate', () async {
        expect(await platform.stopHighRefreshRate(), false);
      });

      test('getRefreshRateInfo', () async {
        final info = await platform.getRefreshRateInfo();
        expect(info['platform'], unsupported.name.toLowerCase());
        expect(info['supported'], false);
        expect(
          info['message'],
          'Refresh rate control not supported on this platform',
        );
        // Never the mocked native values
        expect(info.containsKey('maximumFramesPerSecond'), false);
        expect(info['currentRefreshRate'], info['currentFramesPerSecond']);
      });

      test('all methods throw with exceptions enabled', () async {
        platform.setExceptionOnUnsupportedPlatform(true);
        final throwsUnsupported = throwsA(
          isA<PlatformException>().having(
            (e) => e.code,
            'code',
            'UNSUPPORTED_PLATFORM',
          ),
        );
        await expectLater(platform.getPlatformVersion(), throwsUnsupported);
        await expectLater(platform.requestHighRefreshRate(), throwsUnsupported);
        await expectLater(platform.stopHighRefreshRate(), throwsUnsupported);
        await expectLater(platform.getRefreshRateInfo(), throwsUnsupported);
      });
    });
  }
}
