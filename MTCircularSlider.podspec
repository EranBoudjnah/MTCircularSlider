#
# Be sure to run `pod lib lint MTCircularSlider.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MTCircularSlider'
  s.version          = '1.1.0'
  s.summary          = 'A circular slider control.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
A feature-rich circular slider control. You can tweak colors, shadows, angles and windings.
This widget tries to conform to UISlider both in naming and default style.
                       DESC

  s.homepage         = 'https://github.com/EranBoudjnah/MTCircularSlider'
  s.screenshots     = 'https://raw.githubusercontent.com/EranBoudjnah/MTCircularSlider/screenshots/screenshots/Simulator%20Screen%20Shot%2016%20Sep%202018.gif'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Eran Boudjnah' => 'eranbou@gmail.com' }
  s.source           = { :git => 'https://github.com/EranBoudjnah/MTCircularSlider.git', :tag => s.version.to_s }
  s.social_media_url = 'https://www.linkedin.com/in/eranboudjnah/'

  s.ios.deployment_target = '12.2'
  s.swift_versions = '5.0'

  s.source_files = 'MTCircularSlider/Classes/**/*'
  
  # s.resource_bundles = {
  #   'MTCircularSlider' => ['MTCircularSlider/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
