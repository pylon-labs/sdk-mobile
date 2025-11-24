require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "RNPylonChat"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => "13.0" }
  s.source       = { :git => "https://github.com/usepylon/pylon-chat-sdk.git", :tag => "#{s.version}" }

  # Bridge files + Copied iOS SDK
  s.source_files = "ios/**/*.{h,m,mm,swift}"
  
  # Exclude demo apps
  s.exclude_files = [
    "demo-app/**/*",
    "../ios/DemoApp/**/*"
  ]

  s.requires_arc = true
  s.swift_version = "5.0"

  s.dependency "React-Core"
  
  # WebKit is required by PylonChat SDK
  s.frameworks = "WebKit"
end

