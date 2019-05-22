#
# Be sure to run `pod lib lint CircularCarousel.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'CircularCarousel'
  s.version          = '1.0.0'
  s.summary          = 'Carousel written in swift to handle custom and unique rolling items. Based on iCarousel.'

  s.homepage         = 'https://github.com/ramotion/circular-carousel'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.authors          = { 'ramotion' => 'peter.s@ramotion.agency' }
  s.source           = { :git => 'https://github.com/ramotion/circular-carousel.git', :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'
  s.source_files = 'Framework/CircularCarousel/*.swift'
  s.swift_version = '5.0'

end
