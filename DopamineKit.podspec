#
# Be sure to run `pod lib lint DopamineKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "DopamineKit"
  s.version          = "3.0.2"
  s.summary          = "A framework to use DopamineLabs machine learning API"

  s.description      = <<-DESC
Make your iOS app habit-forming using the DopamineAPI.

This packages provides a framework for interacting with the DopamineAPI from a Cocoa based iOS application. After you have received your API key and configured the actions and reinforcements relevant to your app on the Dopamine Developer Dashboard, you may use this framework to place 'tracking', and 'reinforcement' calls from inside your app that will communicate directly with the DopamineAPI.
                       DESC

  s.homepage         = "https://github.com/DopamineLabs/DopamineAPI_Swift-CocoaPod"
  s.license          = 'MIT'
  s.author           = { "Akash Desai" => "kash650@gmail.com" }
  s.source           = { :git => "https://github.com/DopamineLabs/DopamineAPI_Swift-CocoaPod.git", :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'
  s.ios.vendored_frameworks = 'DopamineKit/Frameworks/DopamineKit.framework'

end
