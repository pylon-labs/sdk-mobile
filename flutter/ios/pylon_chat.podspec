#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint pylon_chat.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'pylon_chat'
  s.version          = '0.1.0'
  s.summary          = "Pylon's chat widget for Flutter."
  s.description      = <<-DESC
In-app customer support for Flutter apps, powered by Pylon.
                       DESC
  s.homepage         = 'https://github.com/pylon-labs/sdk-mobile'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Pylon' => 'support@usepylon.com' }
  s.source           = { :path => '.' }

  # Includes the vendored iOS SDK under Classes/PylonChat/.
  s.source_files = 'Classes/**/*'

  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.frameworks = 'WebKit'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
