import 'flutter_refresh_rate_control_platform_interface.dart';

class FlutterRefreshRateControl {
  bool _exceptionOnUnsupportedPlatform = false;
  bool get exceptionOnUnsupportedPlatform => _exceptionOnUnsupportedPlatform;
  set exceptionOnUnsupportedPlatform(bool value) {
    _exceptionOnUnsupportedPlatform = value;
    FlutterRefreshRateControlPlatform.instance
        .setExceptionOnUnsupportedPlatform(value);
  }

  /// Get the platform version, e.g. "Android 12", "iOS 15"
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
  /// Returns a map containing refresh rate information.
  ///
  /// Due to a typo, Android has currentRefreshRate and iOS has
  /// currentFramesPerSecond. So, I have aliased both.
  ///
  /// The result varies by platform and version:
  /// ================= All platforms =================
  ///   'platform' // the current platform as a string
  ///   'supported' // bool indicating whether current platform is supported
  ///
  /// ============ Unsupported platform only ===========
  ///   'message' // string: "Refresh rate control not supported on this platform"
  ///
  /// ==================== iOS only ====================
  ///   ** iOS >= 10.3 **
  ///     'maximumFramesPerSecond' // The maximum refresh rate reported by the system
  ///     'currentFramesPerSecond', 'currentRefreshRate' // 1/(the target timestamp - timestamp)
  ///     'duration' // the frame duration as reported by the system
  ///     'timestamp' // the timestamp of the current frame as reported by the system
  ///     'targetTimestamp' // the timestamp of the next frame as reported by the system
  ///   ** iOS > 15.0 **
  ///     'preferredFrameRateRange' // map, containing the following:
  ///       'minimum' // the minimum preferred rate
  ///       'maximum' // the maximum preferred rate
  ///       'preferred' // the preferred refresh rate
  /// ================== Android only ==================
  ///   'maximumFramesPerSecond' // the maximum refresh rate in Hz
  ///   'currentFramesPerSecond', 'currentRefreshRate' // the current refresh rate in Hz
  ///   'highRefreshRateEnabled' // whether high refresh rate mode is currently enabled
  ///   'androidVersion' // the Android version of the device
  ///   'deviceModel' // the manufacturer and model of the device OS
  ///   ** Android >= M **
  ///     'supportedModes' // a list of supported refresh rates in Hz
  ///     'currentMode'  // A map containing the following:
  ///       'modeId' // the id of the resolution/refresh rate mode currently in use
  ///       'refreshRate' // the refresh rate of the current mode in Hz
  ///       'width' // the width of the current mode in pixels
  ///       'height' // the height of the current mode in pixels
  Future<Map<String, dynamic>> getRefreshRateInfo() {
    return FlutterRefreshRateControlPlatform.instance.getRefreshRateInfo();
  }
}
