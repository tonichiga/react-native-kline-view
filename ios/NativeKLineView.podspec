Pod::Spec.new do |s|
  s.name         = "NativeKLineView"
  s.version      = "1.0.0"
  s.summary      = "NativeKLineView"
  s.description  = <<-DESC
                  NativeKLineView
                   DESC
  s.homepage     = "https://github.com/hellohublot/native-kline-view"
  s.license      = "MIT"
  s.author       = { "hellohublot" => "hellohublot@gmail.com" }
  s.platform     = :ios, "13.0"
  s.source       = { :git => "https://github.com/hellohublot/native-kline-view.git", :tag => s.version.to_s }
  s.source_files  = "Classes/**/*", "ios/Classes/**/*"
  s.exclude_files    = [
  	'ios/Classes/RNKLineView.swift',
    'ios/Classes/RNKLineView.m',
    'ios/Classes/Bridge.h',
    'ios/Classes/HTKLineContainerView.swift',
    'Classes/RNKLineView.swift',
    'Classes/RNKLineView.m',
    'Classes/Bridge.h',
    'Classes/HTKLineContainerView.swift'
  ]
  s.requires_arc = true
  s.swift_version = "4.0"

  s.dependency 'lottie-ios', '~> 4.5.0'
end
