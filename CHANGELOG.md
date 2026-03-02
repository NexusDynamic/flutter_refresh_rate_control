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
