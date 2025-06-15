# flutter_refresh_rate_control

A Flutter plugin that allows you to request high refresh rate mode on Android and iOS devices. This plugin provides a simple API to attempt to enable the highest possible refresh rate for your Flutter application.

## Platform Support

| Platform | Support | Min Version | Behavior |
|----------|---------|-------------|----------|
| Android  | ✅      | API 23 (Android 6.0) | Full functionality |
| iOS      | ✅      | iOS 10.3 | Full functionality |
| Web      | ⚠️      | N/A | No-op (returns false/empty) |
| Windows  | ⚠️      | N/A | No-op (returns false/empty) |
| macOS    | ⚠️      | N/A | No-op (returns false/empty) |
| Linux    | ⚠️      | N/A | No-op (returns false/empty) |

**Note**: Unsupported platforms will gracefully return `false` for control methods and empty/default values for info methods. You can optionally enable exceptions for unsupported platforms (see [Exception Handling](#exception-handling)).

## Features

- Request the highest available refresh rate on supported devices
- Stop high refresh rate mode to return to normal power consumption
- Get detailed information about device refresh rate capabilities
- Cross-platform support for Android and iOS
- Graceful handling of unsupported platforms (no-op by default)
- Optional exception throwing for unsupported platforms

## Important Limitations

⚠️ **This plugin only attempts to request the highest possible refresh rate.** There are several factors that may prevent achieving high refresh rates:

### System-Level Limitations
- **Low Battery Mode**: Most devices disable high refresh rates when battery is low
- **Thermal Throttling**: Devices may reduce refresh rate when overheating
- **Power Management**: System may override refresh rate settings to preserve battery
- **Display Hardware**: Not all devices support high refresh rates
- **App Background State**: High refresh rates may be disabled when app is not in foreground

### Platform-Specific Behavior

While the plugin will not cause problems on unsupported platforms, the behavior is as follows:

- **Android**: Depends on device manufacturer implementation and Android version (e.g. 90Hz, 120Hz display with "Smooth Display" or manufacturer equivalent enabled)
- **iOS**: Requires ProMotion displays (iPhone 13 Pro+, iPad Pro models)
- **Adaptive Refresh**: Some devices use variable refresh rates based on content

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_refresh_rate_control: ^0.0.1
```

Then run:

```bash
flutter pub get
```

### iOS Setup

For iOS, ensure you have the following in your [`Info.plist`](example/ios/Runner/Info.plist) to allow high refresh rates: (this should already be included by Flutter)

```xml
<key>CADisableMinimumFrameDurationOnPhone</key>
<true/>
```

### Android Setup

For Android, ensure you have the following in your [`res/values/styles.xml`](example/android/app/src/main/res/values/styles.xml):

```xml
<style name="frameRatePowerSavingsBalancedDisabled">
    <item name="android:windowIsFrameRatePowerSavingsBalanced">false</item>
</style>
```

Note: This disables Adaptive Refresh Rate (ARR). See: [Optimize frame rate with adaptive refresh rate](https://developer.android.com/develop/ui/views/animations/adaptive-refresh-rate#enable-disable-arr) for more information.

## Usage

### Basic Example

```dart
import 'package:flutter_refresh_rate_control/flutter_refresh_rate_control.dart';

final _refreshRateControl = FlutterRefreshRateControl();

// Request high refresh rate
try {
  bool success = await _refreshRateControl.requestHighRefreshRate();
  if (success) {
    print('High refresh rate enabled');
  } else {
    print('Failed to enable high refresh rate');
  }
} catch (e) {
  print('Error: $e');
}

// Get refresh rate information
try {
  Map<String, dynamic> info = await _refreshRateControl.getRefreshRateInfo();
  print('Current refresh rate: ${info['currentRefreshRate']}');
  print('Maximum refresh rate: ${info['maximumFramesPerSecond']}');
} catch (e) {
  print('Error getting refresh rate info: $e');
}

// Stop high refresh rate mode
try {
  bool success = await _refreshRateControl.stopHighRefreshRate();
  if (success) {
    print('Returned to normal refresh rate');
  }
} catch (e) {
  print('Error: $e');
}
```

### Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_refresh_rate_control/flutter_refresh_rate_control.dart';

class RefreshRateScreen extends StatefulWidget {
  @override
  _RefreshRateScreenState createState() => _RefreshRateScreenState();
}

class _RefreshRateScreenState extends State<RefreshRateScreen> {
  final _refreshRateControl = FlutterRefreshRateControl();
  bool _isHighRefreshRate = false;
  Map<String, dynamic> _info = {};

  @override
  void initState() {
    super.initState();
    _loadRefreshRateInfo();
  }

  Future<void> _loadRefreshRateInfo() async {
    try {
      final info = await _refreshRateControl.getRefreshRateInfo();
      setState(() {
        _info = info;
      });
    } catch (e) {
      print('Error loading refresh rate info: $e');
    }
  }

  Future<void> _toggleRefreshRate() async {
    try {
      bool success;
      if (_isHighRefreshRate) {
        success = await _refreshRateControl.stopHighRefreshRate();
      } else {
        success = await _refreshRateControl.requestHighRefreshRate();
      }
      
      if (success) {
        setState(() {
          _isHighRefreshRate = !_isHighRefreshRate;
        });
        await _loadRefreshRateInfo();
      }
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Refresh Rate Control')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${_isHighRefreshRate ? "High" : "Normal"} Refresh Rate'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _toggleRefreshRate,
              child: Text(_isHighRefreshRate ? 'Disable High Refresh Rate' : 'Enable High Refresh Rate'),
            ),
            SizedBox(height: 16),
            Text('Device Information:'),
            ..._info.entries.map((e) => Text('${e.key}: ${e.value}')),
          ],
        ),
      ),
    );
  }
}
```

## Exception Handling

By default, the plugin gracefully handles unsupported platforms by returning `false` for control methods and empty/informational data for info methods. However, you can optionally enable exceptions for unsupported platforms:

### Default Behavior (No Exceptions)

```dart
final _refreshRateControl = FlutterRefreshRateControl();

// On unsupported platforms, these return false/empty without throwing
bool success = await _refreshRateControl.requestHighRefreshRate(); // Returns false
Map<String, dynamic> info = await _refreshRateControl.getRefreshRateInfo(); 
// Returns: {'platform': 'web', 'supported': false, 'message': '...'}
```

### Enable Exceptions for Unsupported Platforms

```dart
final _refreshRateControl = FlutterRefreshRateControl();

// Enable exceptions for unsupported platforms
_refreshRateControl.exceptionOnUnsupportedPlatform = true;

try {
  bool success = await _refreshRateControl.requestHighRefreshRate();
} on PlatformException catch (e) {
  if (e.code == 'UNSUPPORTED_PLATFORM') {
    print('Refresh rate control not supported on ${e.details}');
  }
}
```

### When to Use Each Approach

**Use default behavior (no exceptions) when:**
- You want your app to work seamlessly across all platforms
- You're building a cross-platform app and want to gracefully degrade features
- You prefer to check return values rather than handle exceptions

**Use exception mode when:**
- You need to explicitly know when a platform is unsupported
- You want to fail fast during development/testing
- You prefer exception-based error handling

## API Reference

### Properties

#### `exceptionOnUnsupportedPlatform`
Controls whether exceptions should be thrown on unsupported platforms.

**Type:** `bool`  
**Default:** `false`

**Usage:**
```dart
final plugin = FlutterRefreshRateControl();
plugin.exceptionOnUnsupportedPlatform = true; // Enable exceptions
bool isEnabled = plugin.exceptionOnUnsupportedPlatform; // Check current state
```

### Methods

#### `requestHighRefreshRate()`
Attempts to enable the highest available refresh rate.

**Returns:** `Future<bool>` - `true` if successful, `false` otherwise

**Throws:** `PlatformException` if an error occurs

#### `stopHighRefreshRate()`
Stops high refresh rate mode and returns to normal refresh rate.

**Returns:** `Future<bool>` - `true` if successful, `false` otherwise

**Throws:** `PlatformException` if an error occurs

#### `getRefreshRateInfo()`
Gets detailed information about the device's refresh rate capabilities.

**Returns:** `Future<Map<String, dynamic>>` containing:

**Common fields:**
- `maximumFramesPerSecond`: Maximum refresh rate supported by the device
- `currentRefreshRate`: Current refresh rate

**iOS-specific fields:**
- `duration`: CADisplayLink duration
- `timestamp`: Current timestamp
- `targetTimestamp`: Target timestamp
- `preferredFrameRateRange`: Frame rate range (iOS 15+)

**Android-specific fields:**
- `supportedModes`: List of all supported display modes
- `currentMode`: Current display mode information
- `highRefreshRateEnabled`: Whether high refresh rate is currently enabled
- `androidVersion`: Android API level
- `deviceModel`: Device manufacturer and model

**Throws:** `PlatformException` if an error occurs

## Platform Implementation Details

### Android Implementation

The Android implementation uses the following APIs:

- **Display.Mode API** (API 23+): For setting preferred display mode
- **SurfaceControl.setFrameRate()** (API 30+): For fine-grained frame rate control
- **WindowManager.LayoutParams**: For display mode preferences

**Key Android APIs:**
- [`Display.Mode`](https://developer.android.com/reference/android/view/Display.Mode)
- [`SurfaceControl.Transaction.setFrameRate()`](https://developer.android.com/reference/android/view/SurfaceControl.Transaction#setFrameRate(android.view.SurfaceControl,%20float,%20int))
- [`WindowManager.LayoutParams.preferredDisplayModeId`](https://developer.android.com/reference/android/view/WindowManager.LayoutParams#preferredDisplayModeId)

**Android Documentation:**
- [Display Modes](https://developer.android.com/guide/topics/display-cutout#display_modes)
- [Frame Rate API](https://developer.android.com/games/sdk/frame-pacing/frame-rate-api)

### iOS Implementation

The iOS implementation uses CADisplayLink for high refresh rate control:

- **CADisplayLink**: For requesting specific frame rates
- **CAFrameRateRange** (iOS 15+): For fine-grained frame rate control
- **UIScreen.maximumFramesPerSecond**: For device capability detection

**Key iOS APIs:**
- [`CADisplayLink`](https://developer.apple.com/documentation/quartzcore/cadisplaylink)
- [`CAFrameRateRange`](https://developer.apple.com/documentation/quartzcore/caframeraterange)
- [`UIScreen.maximumFramesPerSecond`](https://developer.apple.com/documentation/uikit/uiscreen/1617837-maximumframespersecond)

**iOS Documentation:**
- [ProMotion Technology](https://developer.apple.com/documentation/quartzcore/optimizing_promotion_refresh_rates_for_iphone_13_pro_and_ipad_pro)
- [CADisplayLink Reference](https://developer.apple.com/documentation/quartzcore/cadisplaylink)

## Troubleshooting

### Common Issues

**High refresh rate not working:**
1. Check if platform is supported (Android/iOS only)
2. Check if device supports high refresh rates
3. Ensure device is not in low battery mode
4. Verify app is in foreground
5. Check device temperature (thermal throttling)

**Methods returning false/empty on supported platforms:**
1. Ensure proper permissions (should not be needed for this plugin)
2. Check platform compatibility
3. Verify device display capabilities
4. Check if `exceptionOnUnsupportedPlatform` is enabled to get detailed error messages

**Unsupported platform behavior:**
- By default: Methods return `false` or informational data without throwing
- With exceptions enabled: `PlatformException` with code `'UNSUPPORTED_PLATFORM'` is thrown
- Use `getRefreshRateInfo()` to check platform support status

### Testing

#### Unit Tests
Run the unit tests to verify platform interface and method channel functionality:
```bash
flutter test
```

#### Integration Tests
Run the integration tests on a real device or simulator to test platform channel communication and FPS monitoring:

```bash
# Android device/emulator
flutter test integration_test/plugin_integration_test.dart

# iOS simulator/device  
flutter test integration_test/plugin_integration_test.dart
```

**Integration test features:**
- Platform channel communication verification
- FPS monitoring (inspired by liblsl_timing FPSoverlay)
- Exception handling validation
- Stress testing with rapid API calls
- Real refresh rate change detection
- Cross-platform compatibility testing

#### Manual Testing Tips

1. Use a device with high refresh rate support
2. Ensure device is charged and not in power saving mode
3. Keep app in foreground during testing
4. Monitor device temperature
5. Test on both supported (Android/iOS) and unsupported platforms
6. Try enabling/disabling exception mode to test error handling

### Performance Considerations

- High refresh rates consume more battery
- May cause device heating during extended use
- Some devices automatically adjust based on content
- Consider user preferences and battery level in your app

## Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests to our [GitHub repository](https://github.com/your-username/flutter_refresh_rate_control).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed history of changes.
