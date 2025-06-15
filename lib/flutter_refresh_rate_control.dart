
import 'flutter_refresh_rate_control_platform_interface.dart';

class FlutterRefreshRateControl {
  bool _exceptionOnUnsupportedPlatform = false;
  bool get exceptionOnUnsupportedPlatform => _exceptionOnUnsupportedPlatform;
  set exceptionOnUnsupportedPlatform(bool value) {
    _exceptionOnUnsupportedPlatform = value;
    FlutterRefreshRateControlPlatform.instance.setExceptionOnUnsupportedPlatform(
      value,
    );
  }

  Future<String?> getPlatformVersion() {
    return FlutterRefreshRateControlPlatform.instance.getPlatformVersion();
  }

  /// Request high refresh rate mode
  /// Returns true if successful, false otherwise
  Future<bool> requestHighRefreshRate() {
    return FlutterRefreshRateControlPlatform.instance.requestHighRefreshRate();
  }

  /// Stop high refresh rate mode and return to normal
  /// Returns true if successful, false otherwise
  Future<bool> stopHighRefreshRate() {
    return FlutterRefreshRateControlPlatform.instance.stopHighRefreshRate();
  }

  /// Get information about the device's refresh rate capabilities
  /// Returns a map containing refresh rate information
  Future<Map<String, dynamic>> getRefreshRateInfo() {
    return FlutterRefreshRateControlPlatform.instance.getRefreshRateInfo();
  }
}
