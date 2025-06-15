import 'dart:io';

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

  final bool isSupported = Platform.isAndroid || Platform.isIOS;

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
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
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    final result = await platform.getPlatformVersion();
    if (isSupported) {
      expect(result, '42');
    } else {
      expect(result, contains('Unsupported platform:'));
    }
  });

  test('requestHighRefreshRate', () async {
    final result = await platform.requestHighRefreshRate();
    if (isSupported) {
      expect(result, true);
    } else {
      expect(result, false);
    }
  });

  test('stopHighRefreshRate', () async {
    final result = await platform.stopHighRefreshRate();
    if (isSupported) {
      expect(result, true);
    } else {
      expect(result, false);
    }
  });

  test('getRefreshRateInfo', () async {
    final info = await platform.getRefreshRateInfo();
    expect(info, isA<Map<String, dynamic>>());
    if (isSupported) {
      expect(info['maximumFramesPerSecond'], 120);
      expect(info['currentRefreshRate'], 60.0);
      expect(info['highRefreshRateEnabled'], false);
    } else {
      expect(info['platform'], Platform.operatingSystem);
      expect(info['supported'], false);
      expect(
        info['message'],
        'Refresh rate control not supported on this platform',
      );
    }
  });

  test('exceptionOnUnsupportedPlatform setter', () {
    expect(platform.exceptionOnUnsupportedPlatform, false);
    platform.setExceptionOnUnsupportedPlatform(true);
    expect(platform.exceptionOnUnsupportedPlatform, true);
    platform.setExceptionOnUnsupportedPlatform(false);
    expect(platform.exceptionOnUnsupportedPlatform, false);
  });

  group('unsupported platform with exceptions enabled', () {
    setUp(() {
      platform.setExceptionOnUnsupportedPlatform(true);
    });

    tearDown(() {
      platform.setExceptionOnUnsupportedPlatform(false);
    });

    test('getPlatformVersion throws on unsupported platform', () async {
      if (!isSupported) {
        expect(
          () async => await platform.getPlatformVersion(),
          throwsA(
            isA<PlatformException>().having(
              (e) => e.code,
              'code',
              'UNSUPPORTED_PLATFORM',
            ),
          ),
        );
      }
    });

    test('requestHighRefreshRate throws on unsupported platform', () async {
      if (!isSupported) {
        expect(
          () async => await platform.requestHighRefreshRate(),
          throwsA(
            isA<PlatformException>().having(
              (e) => e.code,
              'code',
              'UNSUPPORTED_PLATFORM',
            ),
          ),
        );
      }
    });

    test('stopHighRefreshRate throws on unsupported platform', () async {
      if (!isSupported) {
        expect(
          () async => await platform.stopHighRefreshRate(),
          throwsA(
            isA<PlatformException>().having(
              (e) => e.code,
              'code',
              'UNSUPPORTED_PLATFORM',
            ),
          ),
        );
      }
    });

    test('getRefreshRateInfo throws on unsupported platform', () async {
      if (!isSupported) {
        expect(
          () async => await platform.getRefreshRateInfo(),
          throwsA(
            isA<PlatformException>().having(
              (e) => e.code,
              'code',
              'UNSUPPORTED_PLATFORM',
            ),
          ),
        );
      }
    });
  });
}
