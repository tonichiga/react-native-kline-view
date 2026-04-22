Pod::Spec.new do |s|
  s.name             = 'native_kline_view'
  s.version          = '0.0.1'
  s.summary          = 'Native KLine View for Flutter.'
  s.description      = <<-DESC
  Native KLine View for Flutter (iOS platform view).
  DESC
  s.homepage         = 'https://github.com/hellohublot/native-kline-view'
  s.license          = { :file => '../../LICENSE' }
  s.author           = { 'hellohublot' => 'hellohublot@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*.{h,m,swift}'
  s.dependency 'Flutter'
  s.dependency 'NativeKLineView'
  s.dependency 'lottie-ios', '~> 4.5.0'
  s.platform     = :ios, '13.0'
  s.swift_version = '4.0'
end
