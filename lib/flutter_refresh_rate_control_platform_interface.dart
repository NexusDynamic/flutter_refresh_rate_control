import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_refresh_rate_control_method_channel.dart';

abstract class FlutterRefreshRateControlPlatform extends PlatformInterface {
  /// Constructs a FlutterRefreshRateControlPlatform.
  FlutterRefreshRateControlPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterRefreshRateControlPlatform _instance =
      MethodChannelFlutterRefreshRateControl();

  /// The default instance of [FlutterRefreshRateControlPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterRefreshRateControl].
  static FlutterRefreshRateControlPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterRefreshRateControlPlatform] when
  /// they register themselves.
  static set instance(FlutterRefreshRateControlPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    instance.setExceptionOnUnsupportedPlatform(
      _instance.exceptionOnUnsupportedPlatform,
    );
    _instance = instance;
  }

  bool get exceptionOnUnsupportedPlatform;

  void setExceptionOnUnsupportedPlatform(bool value) {
    throw UnimplementedError(
      'setExceptionOnUnsupportedPlatform() has not been implemented.',
    );
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<bool> requestHighRefreshRate() {
    throw UnimplementedError(
      'requestHighRefreshRate() has not been implemented.',
    );
  }

  Future<bool> stopHighRefreshRate() {
    throw UnimplementedError('stopHighRefreshRate() has not been implemented.');
  }

  Future<Map<String, dynamic>> getRefreshRateInfo() {
    throw UnimplementedError('getRefreshRateInfo() has not been implemented.');
  }
}
