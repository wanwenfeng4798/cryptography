#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint cryptography_flutter_pro.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'cryptography_flutter_pro'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  s.source           = { :path => '.' }
  s.source_files = 'cryptography_flutter_pro/Sources/cryptography_flutter_pro/**/*'

  s.resource_bundles = {'cryptography_flutter_pro_privacy' => ['cryptography_flutter_pro/Sources/cryptography_flutter_pro/PrivacyInfo.xcprivacy']}

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.15'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
