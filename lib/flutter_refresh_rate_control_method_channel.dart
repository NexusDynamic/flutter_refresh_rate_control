import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_refresh_rate_control_platform_interface.dart';

/// An implementation of [FlutterRefreshRateControlPlatform] that uses method channels.
class MethodChannelFlutterRefreshRateControl
    extends FlutterRefreshRateControlPlatform {
  bool _exceptionOnUnsupportedPlatform = false;

  /// Indicates whether an exception should be thrown on unsupported platforms.
  /// If set to true, an exception will be thrown when trying to use refresh rate
  /// control on a platform that does not support it (e.g., web, Windows, Linux).
  @override
  bool get exceptionOnUnsupportedPlatform => _exceptionOnUnsupportedPlatform;

  @override
  /// Sets whether an exception should be thrown on unsupported platforms.
  void setExceptionOnUnsupportedPlatform(bool value) {
    _exceptionOnUnsupportedPlatform = value;
  }

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final MethodChannel methodChannel = const MethodChannel(
    'com.zeyus.flutter_refresh_rate_control/manage',
  );

  /// The current platform as a lowercase string, e.g. "android", "ios", "web".
  String get _platformName =>
      kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase();

  bool get _isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  bool _checkPlatform() {
    if (exceptionOnUnsupportedPlatform && !_isSupported) {
      throw PlatformException(
        code: 'UNSUPPORTED_PLATFORM',
        message:
            'Refresh rate control is only supported on Android, iOS and macOS platforms',
        details: 'Current platform: $_platformName',
      );
    }
    return _isSupported;
  }

  /// Invokes [method] on the native side.
  ///
  /// Returns null if the native plugin is not registered (e.g. in widget
  /// tests), unless [exceptionOnUnsupportedPlatform] is set.
  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    try {
      return await methodChannel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      if (exceptionOnUnsupportedPlatform) rethrow;
      return null;
    }
  }

  /// The refresh rate Flutter reports for the display, if there is one.
  double? get _displayRefreshRate {
    try {
      return PlatformDispatcher.instance.views.firstOrNull?.display.refreshRate;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> getPlatformVersion() async {
    if (!_checkPlatform()) {
      return 'Unsupported platform: $_platformName';
    }
    return _invoke<String>('getPlatformVersion');
  }

  @override
  Future<bool> requestHighRefreshRate() async {
    if (!_checkPlatform()) {
      return false;
    }
    return await _invoke<bool>('requestHighRefreshRate') ?? false;
  }

  @override
  Future<bool> stopHighRefreshRate({bool force = false}) async {
    if (!_checkPlatform()) {
      return false;
    }
    return await _invoke<bool>('stopHighRefreshRate', {'force': force}) ??
        false;
  }

  @override
  Future<Map<String, dynamic>> getRefreshRateInfo() async {
    if (!_checkPlatform()) {
      // Nothing can be requested here, but Flutter still knows the rate
      final refreshRate = _displayRefreshRate;
      return {
        'platform': _platformName,
        'supported': false,
        'message': 'Refresh rate control not supported on this platform',
        if (refreshRate != null) ...{
          'currentRefreshRate': refreshRate,
          'currentFramesPerSecond': refreshRate,
        },
      };
    }
    final defaultResult = {'platform': _platformName, 'supported': true};
    final result =
        (await _invoke<Map<dynamic, dynamic>>(
          'getRefreshRateInfo',
        ))?.cast<String, dynamic>();
    if (result == null) {
      return defaultResult;
    }
    // Due to a typo, Android has currentRefreshRate and iOS has currentFramesPerSecond.
    // So now you can use either :P
    result['currentRefreshRate'] ??= result['currentFramesPerSecond'];
    result['currentFramesPerSecond'] ??= result['currentRefreshRate'];
    return Map<String, dynamic>.from(defaultResult)..addAll(result);
  }
}
