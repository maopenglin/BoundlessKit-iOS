# DopamineKit

<!--[![CI Status](http://img.shields.io/travis/DopamineLabs/DopamineKit-iOS.svg?style=flat) ](https://travis-ci.org/DopamineLabs/DopamineKit-iOS)-->
[![Version](https://img.shields.io/cocoapods/v/DopamineKit.svg?style=flat)](http://cocoapods.org/pods/DopamineKit)
[![License](https://img.shields.io/cocoapods/l/DopamineKit.svg?style=flat)](http://cocoapods.org/pods/DopamineKit)
[![Platform](https://img.shields.io/cocoapods/p/DopamineKit.svg?style=flat)](http://cocoapods.org/pods/DopamineKit)

# What is DopamineKit?

DopamineKit provides wrappers for accessing the DopamineAPI and expressive UI reinforcements for your app.

Get your free API key at [http://dashboard.usedopamine.com/](http://dashboard.usedopamine.com/)

Learn more at [http://usedopamine.com](http://usedopamine.com)

### Looking for an iOS Example App?

A simple "To Do List" iOS App is included in the [DopamineKit-iOS-HelloWorld repo](https://github.com/DopamineLabs/DopamineKit-iOS-HelloWorld) to demonstrate how DopamineKit may be used in your code.

## Set up DopamineKit

  1. First, make sure you have received your API key and other credentials, which are in the configuration file __DopamineProperties.plist__ automatically generated from the [Dopamine Developer Dashboard](http://dashboard.usedopamine.com). 

  2. Drag __DopamineProperties.plist__ into your project group. Ensure that the .plist was added to app target > Build Phases > Copy Bundle Resources as shown in the image below.  

  3. Import the DopamineKit framework by using [CocoaPods](https://cocoapods.org/) (the Pod name is `DopamineKit`), or by [directly downloading](
https://github.com/DopamineLabs/DopamineKit-iOS-binary/) the framework.

  ![Workspace snapshot](readme/TestApp with DopamineKit and DopamineProperties.png)
    *Shown is a Swift project using the CocoaPods dependency manager*
    
  4. Import the DopamineKit framework

  ```swift
  // Swift
  import DopamineKit
  ```
  
  ```objective-c
  // Objective-C
  #import <DopamineKit/DopamineKit-Swift.h>
  ```
  
  5. Start using Dopamine! The main features of DopamineAPI are the `reinforce()` and `track()` functions. These should be added as a response to any of the _actions_ to be reinforced or tracked.
  

###### DopamineKit.reinforce()

  -  For example, when a user marks a task as completed in a "To Do List" app or finishes a workout in a "Fitness" app, you should call `reinforce()`.

  ```swift
  // Swift
  DopamineKit.reinforce("some_action", completion: {
  reinforcement in
		
		switch(reinforcement){
			// Use any rewarding UI components you made like, 
			// self.showInspirationalQuote() or self.showFunnyMeme().
			// For now, we'll try out Dopamine's CandyBar for a simple reward.

		case "thumbsUp" :
			CandyBar(title: "Great job!", icon: Candy.ThumbsUp).show(duration: 1.2)
                                
		case "stars" :
			CandyBar(title: "Great job!", icon: Candy.Stars).show(duration: 1.2)
                                
		case "medalStar" :
			CandyBar(title: "Great job!", icon: Candy.MedalStar).show(duration: 1.2)
                            
		default:
			// Show nothing! This is called a neutral response, 
			// and builds up the good feelings for the next surprise!
			return

		}
})
  ```

  ```objective-c
  // Objective-C
  [DopamineKit reinforce:@"some_action" metaData:nil timeoutSeconds:2.0 completion:^(NSString* reinforcement){
        
        if([reinforcement isEqualToString:@"quote"]){
            // show some positive reinforcement View
            [self showInspirationalQuote]
            
        } else if([reinforcement isEqualToString:@"meme"]){
            // some other feel good reinforcement View
            [self showFunnyMeme]
            
        } else{
            // Show nothing! This is called a neutral response, 
            // and builds up the good feelings for the next surprise!
            return;
        }
    }];
  
  ```
  
###### DopamineKit.track()

  - The `track()` function is used to track other user actions. Using `track()` calls gives Dopamine a better understanding of user behavior, and will make your optimization and analytics better. 
  - Continuing the example, you could use the `track()` function to record `applicationDidBecomeActive()` in the  "To Do List" app, or  record `userCheckedDietHistory()` in the "Fitness" app.

  
  Let's track when a user adds a food item in a "Fitness" app. We will also add the calories for the item in the `metaData` field to gather richer information about user engagement in my app.
  
  ```swift
  // Swift
  let calories:Int = 400
  DopamineKit.track("foodItemAdded", metaData: ["cals":calories])
  ```
  
  ```objective-c
  // Objective-C
  NSNumber* calories = [NSNumber numberWithInt:400];
  [DopamineKit track:@"foodItemAdded" metaData:@{@"cals":calories} completion:^(NSString* s){}];
   ```

  
  
## Super Users

There are additional parameters for the `track()` and `reinforce()` functions that are used to gather rich information from your app and better create a user story of better engagement.

========

####Tracking Calls

A tracking call should be used to record and communicate to DopamineAPI that a particular action has been performed by the user, each of these calls will be used to improve the reinforcement model used for the particular user. The tracking call itself is asynchronous and non-blocking, and returns a status code (200 for success, other for errors) which can be ignored for the most part. Failed tracking calls will not return errors, but will be noted in the NSLog.

######General syntax

```
Dopamine.track(actionID, metaData)
```

######Parameters:

 - `actionID: String` - is a unique name for the action that the user has performed

 - `metaData: [String:AnyObject]` - (optional) is any additional data to be sent to the API

========

####Reinforcement Calls

A reinforcement call should be used when the user has performed a particular action that you wish to become a 'habit', the reinforcement call will return the name of the feedback function that should be called to inform, delight or congratulate the user. The names of the reinforcement functions, the feedback functions and their respective pairings may be found and configured on the developer dashboard.

######General syntax

```
Dopamine.reinforce(actionID, metaData, completion)
```

######Parameters:

 - `actionID: String` - is a unique name for the action that the user has performed

 - `metaData: [String:AnyObject]` - (optional) is any additional data to be sent to the API

 - `completion: String -> ()` - is a closure which receives a the reinforcement decisions as a String

The reinforcement call itself takes the actionID as a required parameter, as well as a trailing closure, which serves as a completion function for the reinforcement response. This closure receives the name of the feedback function as an String input argument.


For more information on using closures, see Apple's [documentation](https://developer.apple.com/library/ios/documentation/Swift/Conceptual/Swift_Programming_Language/Closures.html).

========

####DopamineProperties.plist
`DopamineProperties.plist` _must_ be contained within your app's _main bundle_. This property list contains configuration variables needed to make valid calls to the API, all of which can be found on your developer dashboard:

 - `appID: String` - uniquely identifies your app, get this from your [developer dashboard](http://dev.usedopamine.com).

 - `versionID: String` -  this is a unique identifier that you choose that marks this implementation as unique in our system. This could be something like 'summer2015Implementation' or 'ClinicalTrial4'. Your `versionID` is what we use to keep track of what users are exposed to what reinforcement and how to best optimize that.

 - `inProduction: Bool` - indicates whether app is in production or development mode, when you're happy with how you're integrating Dopamine and ready to launch set this argument to `true`. This will activate optimized reinforcement and start your billing cycle. While set to `false` your app will receive dummy reinforcement, new users will not be registered with our system, and no billing occurs.

 - `productionSecret: String` - secret key for production

 - `developmentSecret: String` - secret key for development