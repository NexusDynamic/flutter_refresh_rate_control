import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_refresh_rate_control_platform_interface.dart';

/// An implementation of [FlutterRefreshRateControlPlatform] that uses method channels.
class MethodChannelFlutterRefreshRateControl
    extends FlutterRefreshRateControlPlatform {
  bool _exceptionOnUnsupportedPlatform = false;

  /// Indicates whether an exception should be thrown on unsupported platforms.
  /// If set to true, an exception will be thrown when trying to use refresh rate
  /// control on a platform that does not support it (e.g., web, desktop).
  @override
  bool get exceptionOnUnsupportedPlatform => _exceptionOnUnsupportedPlatform;

  @override
  /// Sets whether an exception should be thrown on unsupported platforms.
  void setExceptionOnUnsupportedPlatform(bool value) {
    _exceptionOnUnsupportedPlatform = value;
  }

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final MethodChannel? methodChannel =
      (Platform.isAndroid || Platform.isIOS)
          ? const MethodChannel('com.zeyus.flutter_refresh_rate_control/manage')
          : null;

  bool _checkPlatform() {
    if (exceptionOnUnsupportedPlatform && methodChannel == null) {
      throw PlatformException(
        code: 'UNSUPPORTED_PLATFORM',
        message:
            'Refresh rate control is only supported on Android and iOS platforms',
        details: 'Current platform: ${Platform.operatingSystem}',
      );
    }
    return methodChannel != null;
  }

  @override
  Future<String?> getPlatformVersion() async {
    if (!_checkPlatform()) {
      return 'Unsupported platform: ${Platform.operatingSystem}';
    }
    final version = await methodChannel!.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<bool> requestHighRefreshRate() async {
    if (!_checkPlatform()) {
      return false;
    }
    final result = await methodChannel!.invokeMethod<bool>(
      'requestHighRefreshRate',
    );
    return result ?? false;
  }

  @override
  Future<bool> stopHighRefreshRate() async {
    if (!_checkPlatform()) {
      return false;
    }
    final result = await methodChannel!.invokeMethod<bool>(
      'stopHighRefreshRate',
    );
    return result ?? false;
  }

  @override
  Future<Map<String, dynamic>> getRefreshRateInfo() async {
    if (!_checkPlatform()) {
      return {
        'platform': Platform.operatingSystem,
        'supported': false,
        'message': 'Refresh rate control not supported on this platform',
      };
    }
    final result = await methodChannel!.invokeMethod('getRefreshRateInfo');
    return Map<String, dynamic>.from(result ?? {});
  }
}
