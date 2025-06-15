import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_refresh_rate_control/flutter_refresh_rate_control.dart';
import 'package:flutter_refresh_rate_control/flutter_refresh_rate_control_platform_interface.dart';
import 'package:flutter_refresh_rate_control/flutter_refresh_rate_control_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterRefreshRateControlPlatform
    with MockPlatformInterfaceMixin
    implements FlutterRefreshRateControlPlatform {
  bool _exceptionOnUnsupportedPlatform = false;

  @override
  bool get exceptionOnUnsupportedPlatform => _exceptionOnUnsupportedPlatform;

  @override
  void setExceptionOnUnsupportedPlatform(bool value) {
    _exceptionOnUnsupportedPlatform = value;
  }

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<bool> requestHighRefreshRate() => Future.value(true);

  @override
  Future<bool> stopHighRefreshRate() => Future.value(true);

  @override
  Future<Map<String, dynamic>> getRefreshRateInfo() => Future.value({
    'maximumFramesPerSecond': 120,
    'currentRefreshRate': 60.0,
    'highRefreshRateEnabled': false,
  });
}

void main() {
  final FlutterRefreshRateControlPlatform initialPlatform =
      FlutterRefreshRateControlPlatform.instance;

  test('$MethodChannelFlutterRefreshRateControl is the default instance', () {
    expect(
      initialPlatform,
      isInstanceOf<MethodChannelFlutterRefreshRateControl>(),
    );
  });

  test('getPlatformVersion', () async {
    FlutterRefreshRateControl flutterRefreshRateControlPlugin =
        FlutterRefreshRateControl();
    MockFlutterRefreshRateControlPlatform fakePlatform =
        MockFlutterRefreshRateControlPlatform();
    FlutterRefreshRateControlPlatform.instance = fakePlatform;

    expect(await flutterRefreshRateControlPlugin.getPlatformVersion(), '42');
  });

  test('requestHighRefreshRate', () async {
    FlutterRefreshRateControl flutterRefreshRateControlPlugin =
        FlutterRefreshRateControl();
    MockFlutterRefreshRateControlPlatform fakePlatform =
        MockFlutterRefreshRateControlPlatform();
    FlutterRefreshRateControlPlatform.instance = fakePlatform;

    expect(
      await flutterRefreshRateControlPlugin.requestHighRefreshRate(),
      true,
    );
  });

  test('stopHighRefreshRate', () async {
    FlutterRefreshRateControl flutterRefreshRateControlPlugin =
        FlutterRefreshRateControl();
    MockFlutterRefreshRateControlPlatform fakePlatform =
        MockFlutterRefreshRateControlPlatform();
    FlutterRefreshRateControlPlatform.instance = fakePlatform;

    expect(await flutterRefreshRateControlPlugin.stopHighRefreshRate(), true);
  });

  test('getRefreshRateInfo', () async {
    FlutterRefreshRateControl flutterRefreshRateControlPlugin =
        FlutterRefreshRateControl();
    MockFlutterRefreshRateControlPlatform fakePlatform =
        MockFlutterRefreshRateControlPlatform();
    FlutterRefreshRateControlPlatform.instance = fakePlatform;

    final info = await flutterRefreshRateControlPlugin.getRefreshRateInfo();
    expect(info, isA<Map<String, dynamic>>());
    expect(info['maximumFramesPerSecond'], 120);
    expect(info['currentRefreshRate'], 60.0);
    expect(info['highRefreshRateEnabled'], false);
  });

  test('exceptionOnUnsupportedPlatform', () async {
    FlutterRefreshRateControl flutterRefreshRateControlPlugin =
        FlutterRefreshRateControl();
    MockFlutterRefreshRateControlPlatform fakePlatform =
        MockFlutterRefreshRateControlPlatform();
    FlutterRefreshRateControlPlatform.instance = fakePlatform;

    expect(
      flutterRefreshRateControlPlugin.exceptionOnUnsupportedPlatform,
      false,
    );

    flutterRefreshRateControlPlugin.exceptionOnUnsupportedPlatform = true;
    expect(
      flutterRefreshRateControlPlugin.exceptionOnUnsupportedPlatform,
      true,
    );
    expect(fakePlatform.exceptionOnUnsupportedPlatform, true);

    flutterRefreshRateControlPlugin.exceptionOnUnsupportedPlatform = false;
    expect(
      flutterRefreshRateControlPlugin.exceptionOnUnsupportedPlatform,
      false,
    );
    expect(fakePlatform.exceptionOnUnsupportedPlatform, false);
  });
}
