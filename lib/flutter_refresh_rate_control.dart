import 'flutter_refresh_rate_control_platform_interface.dart';

class FlutterRefreshRateControl {
  /// Whether to throw on unsupported platforms instead of doing nothing.
  /// This setting is shared by all instances.
  bool get exceptionOnUnsupportedPlatform =>
      FlutterRefreshRateControlPlatform.instance.exceptionOnUnsupportedPlatform;
  set exceptionOnUnsupportedPlatform(bool value) {
    FlutterRefreshRateControlPlatform.instance
        .setExceptionOnUnsupportedPlatform(value);
  }

  /// Get the platform version, e.g. "Android 12", "iOS 15", "macOS Version 15.0"
  Future<String?> getPlatformVersion() {
    return FlutterRefreshRateControlPlatform.instance.getPlatformVersion();
  }

  /// Request high refresh rate mode
  /// Returns true if successful, false otherwise
  Future<bool> requestHighRefreshRate() {
    return FlutterRefreshRateControlPlatform.instance.requestHighRefreshRate();
  }

  /// Stop high refresh rate mode and return to how things were before
  /// [requestHighRefreshRate] was called.
  /// Returns true if successful, false otherwise
  ///
  /// On Android the request changes settings of the app window. If one of
  /// them no longer has the value this plugin gave it, something else has
  /// changed it since, and it is left as it is. Set [force] to put the
  /// previous value back anyway. [force] has no effect on other platforms.
  Future<bool> stopHighRefreshRate({bool force = false}) {
    return FlutterRefreshRateControlPlatform.instance.stopHighRefreshRate(
      force: force,
    );
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
  ///   'currentFramesPerSecond', 'currentRefreshRate' // the display refresh rate Flutter reports, if known
  ///
  /// ================== iOS and macOS ==================
  ///   'maximumFramesPerSecond' // The maximum refresh rate reported by the system (macOS >= 12)
  ///   ** Only while high refresh rate mode is requested **
  ///     'currentFramesPerSecond', 'currentRefreshRate' // 1/(the target timestamp - timestamp)
  ///       of the plugin's own display link, missing until it has fired once
  ///     'duration' // the frame duration as reported by the system
  ///     'timestamp' // the timestamp of the current frame as reported by the system
  ///     'targetTimestamp' // the timestamp of the next frame as reported by the system
  ///     'preferredFrameRateRange' // (iOS >= 15.0) map, containing the following:
  ///       'minimum' // the minimum preferred rate
  ///       'maximum' // the maximum preferred rate
  ///       'preferred' // the preferred refresh rate
  /// =================== macOS only ===================
  ///   'highRefreshRateEnabled' // whether high refresh rate mode is currently requested
  ///   ** macOS >= 12 **
  ///     'minimumRefreshInterval' // shortest time between screen updates in seconds
  ///     'maximumRefreshInterval' // longest time between screen updates in seconds
  /// ================== Android only ==================
  ///   'maximumFramesPerSecond' // the maximum refresh rate in Hz
  ///   'currentFramesPerSecond', 'currentRefreshRate' // the current refresh rate in Hz
  ///   'highRefreshRateEnabled' // whether high refresh rate mode is currently enabled
  ///   'surfaceFrameRateRequested' // whether the rate is also requested on the surface Flutter renders into
  ///   'androidVersion' // the Android version of the device
  ///   'deviceModel' // the manufacturer and model of the device OS
  ///   'supportedModes' // a list of supported display modes, each a map like 'currentMode'
  ///   'currentMode'  // A map containing the following:
  ///     'modeId' // the id of the resolution/refresh rate mode currently in use
  ///     'refreshRate' // the refresh rate of the current mode in Hz
  ///     'width' // the width of the current mode in pixels
  ///     'height' // the height of the current mode in pixels
  Future<Map<String, dynamic>> getRefreshRateInfo() {
    return FlutterRefreshRateControlPlatform.instance.getRefreshRateInfo();
  }
}
