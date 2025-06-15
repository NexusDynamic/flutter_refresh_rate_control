#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_refresh_rate_control.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_refresh_rate_control'
  s.version          = '0.0.3+1'
  s.summary          = 'A Flutter plugin that allows you to request high refresh rate mode on Android and iOS devices.'
  s.description      = <<-DESC
A Flutter plugin that allows you to request high refresh rate mode on Android and iOS devices.
This plugin provides a simple API to attempt to enable the highest possible refresh rate for your Flutter application.
                       DESC
  s.homepage         = 'http://zeyus.com'
  s.license          = { :file => '../LICENSE', :type => 'MIT' }
  s.author           = { 'Your Company' => 'dev@zeyus.com' }
  s.source           = { :git => 'https://github.com/NexusDynamic/flutter_refresh_rate_control.git', :tag => s.version.to_s }
  s.source_files = 'flutter_refresh_rate_control/Sources/flutter_refresh_rate_control/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  s.resource_bundles = {'flutter_refresh_rate_control_privacy' => ['flutter_refresh_rate_control/Sources/flutter_refresh_rate_control/PrivacyInfo.xcprivacy']}
end
