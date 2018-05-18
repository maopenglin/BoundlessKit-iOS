#
# Be sure to run `pod lib lint BoundlessKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'BoundlessKit'
  s.version          = '5.4.2-core2'
  s.summary          = 'A framework to use BoundlessAI reinforcement for iOS'
  s.homepage         = 'https://github.com/BoundlessAI/BoundlessKit-iOS'
  s.social_media_url = 'https://twitter.com/boundlessAI'

  s.description      = <<-DESC
  Make your iOS app habit-forming using BoundlessAI.
  
  This packages provides a framework for interacting with BoundlessAI from a Cocoa based iOS application. After you have received your API key and configured the actions and reinforcements relevant to your app on the Boundless Developer Dashboard, you may use this framework to place 'tracking', and 'reinforcement' calls from inside your app that will communicate directly with BoundlessAI.
                          DESC

  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'BoundlessAI' => 'team@boundless.ai' }
  s.source           = { :git => 'https://github.com/BoundlessAI/BoundlessKit-iOS.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'

  s.source_files = 'BoundlessKit/Classes/**/*'
  
  s.resource_bundles = {
   'BoundlessKit' => ['BoundlessKit/Assets/*.png']
  }

  s.public_header_files = 'BoundlessKit/Classes/**/*.h'
  
end
