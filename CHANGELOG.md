# 0.1.0+0

* Added macOS support (macOS 14+)
* Android: Only use the current resolution modes
* Android: `stopHighRefreshRate()` restores the previous preference
* Added `force` to `stopHighRefreshRate()` to restore the previous setting, even if something else changed it
* Android: Adaptive Refresh Rate is disabled by the plugin on API 35+, the `styles.xml` setup step is no longer needed
* Android: the request is made again when the activity is recreated (so it will continue to work after suspend)
* iOS: requests the display's maximum refresh rate (instead of 120Hz)
* iOS: `currentFramesPerSecond` is no longer infinite before the display link has fired
* Fixed all methods throwing on web
* `getRefreshRateInfo()` reports `currentRefreshRate` on unsupported platforms
* Methods fall back to no-op results when the native plugin is not registered (e.g. in widget tests)
* `exceptionOnUnsupportedPlatform` is now consistent between instances
* Added an integration test that measures the frame rate
* Updated example app, it now displays FPS and can be configured to turn off animation or lower the FPS counter update rate
  this lets you test various conditions - but the app render rate will slow down no matter what the display is requested at.
  Forcing frame rendering would make it render at a higher rate, but it would also trigger VRR on some devices, so it isn't
  a good indication of what's actually happening with the display.

# 0.0.7+0

* Remove KGP
* Update method channel invocation
* Update iOS to use swift package manager
* Remove pods

# 0.0.6+0

* Readme update, added TOC and clarified some documentation.

# 0.0.5+1

* Updated dependencies
* Upgraded gradle to 8.13.2
* Updated documentation thanks [@makoConstruct](https://github.com/makoConstruct) ([Issue #1](https://github.com/NexusDynamic/flutter_refresh_rate_control/issues/1))
* Added documentation for the `getRefreshRateInfo()` method
* Added default keys for the `getRefreshRateInfo()` that are always returned.
  - `platform`: (string) The platform the app is running on, e.g. "android", "ios", "windows", "linux", "macos"
  - `supported`: (bool) Whether refresh rate control is supported on the current platform
* Aliased 'currentFramesPerSecond', 'currentRefreshRate' for iOS and Android so both will give you the same value.
# 0.0.4+1

* Lower Dart SDK minimum version to `3.7.0`

# 0.0.3+1

* Migrated to Swift Package Manager
* Implemented `getPlatformVersion` method for iOS and Android

# 0.0.2

* Documentation fixes
* Shortened package description

# 0.0.1

* Initial release of the package
* Attempts to set high refresh rate for iOS and Android devices
