#
#  Be sure to run `pod spec lint DopamineKit.podspec' to ensure this is a
#  valid spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

# ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
#
#  These will help people to find your library, and whilst it
#  can feel like a chore to fill in it's definitely to your advantage. The
#  summary should be tweet-length, and the description more in depth.
#

s.name             = "DopamineKit"
s.version          = "5.2.0"
s.summary          = "A framework to use DopamineLabs reinforcement API written in Swift 4"
s.homepage         = "https://github.com/DopamineLabs/DopamineKit-iOS"
s.social_media_url = 'https://twitter.com/usedopamine'

s.description      = <<-DESC
Make your iOS app habit-forming using the DopamineAPI.

This packages provides a framework for interacting with the DopamineAPI from a Cocoa based iOS application. After you have received your API key and configured the actions and reinforcements relevant to your app on the Dopamine Developer Dashboard, you may use this framework to place 'tracking', and 'reinforcement' calls from inside your app that will communicate directly with the DopamineAPI.
DESC


# ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
#
#  Licensing your code is important. See http://choosealicense.com for more info.
#  CocoaPods will detect a license file if there is a named LICENSE*
#  Popular ones are 'MIT', 'BSD' and 'Apache License, Version 2.0'.
#

s.license      = { :type => "MIT", :file => "LICENSE.txt" }


# ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
#
#  Specify the authors of the library, with email addresses.
#

s.author             = { "Akash Desai" => "team@usedopamine.com" }

# ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
#
#  If this Pod runs only on iOS or OS X, then specify the platform and
#  the deployment target. You can optionally include the target after the platform.
#

s.ios.deployment_target = '9.0'

# ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
#
#  Specify the location from where the source should be retrieved.
#  Supports git, hg, bzr, svn and HTTP.
#

s.source           = { :git => "https://github.com/DopamineLabs/DopamineKit-iOS.git", :tag => s.version.to_s }


# ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
#
#  CocoaPods is smart about how it includes source code. For source files
#  giving a folder will include any swift, h, m, mm, c & cpp files.
#  For header files it will include any header in the folder.
#  Not including the public_header_files will make all headers public.
#

s.source_files = "Sources/**/*"
s.resource_bundles = {
'DopamineKit' => ['Sources/Assets/*.png']
}

s.public_header_files = "Sources/**/*.h"

end
