#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_refresh_rate_control.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_refresh_rate_control'
  s.version          = '0.1.0'
  s.summary          = 'A Flutter plugin that allows you to request high refresh rate mode on Android, iOS and macOS devices.'
  s.description      = <<-DESC
A Flutter plugin that allows you to request high refresh rate mode on Android, iOS and macOS devices.
This plugin provides a simple API to attempt to enable the highest possible refresh rate for your Flutter application.
                       DESC
  s.homepage         = 'http://zeyus.com'
  s.license          = { :file => '../LICENSE', :type => 'MIT' }
  s.author           = { 'zeyus' => 'dev@zeyus.com' }
  s.source           = { :git => 'https://github.com/NexusDynamic/flutter_refresh_rate_control.git', :tag => s.version.to_s }
  s.source_files = 'flutter_refresh_rate_control/Sources/flutter_refresh_rate_control/**/*.swift'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.15'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'

  s.resource_bundles = {'flutter_refresh_rate_control_privacy' => ['flutter_refresh_rate_control/Sources/flutter_refresh_rate_control/PrivacyInfo.xcprivacy']}
end
