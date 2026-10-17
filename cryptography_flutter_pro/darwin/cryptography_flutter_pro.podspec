#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint cryptography_flutter_pro.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'cryptography_flutter_pro'
  s.version          = '0.1.1'
  s.summary          = 'Native cryptographic algorithms for Flutter.'
  s.description      = <<-DESC
Native cryptographic algorithms for Flutter on iOS and macOS.
                       DESC
  s.homepage         = 'https://github.com/wanwenfeng4798/cryptography'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'cryptography_flutter_pro/Sources/cryptography_flutter_pro/**/*'
  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'
  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'

  # Flutter.framework does not contain a i386 slice.
  s.ios.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.osx.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'

  s.resource_bundles = {'cryptography_flutter_pro_privacy' => ['cryptography_flutter_pro/Sources/cryptography_flutter_pro/PrivacyInfo.xcprivacy']}
end
