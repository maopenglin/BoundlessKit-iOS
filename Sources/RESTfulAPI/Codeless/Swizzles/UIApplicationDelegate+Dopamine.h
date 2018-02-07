//
//  UIApplicationDelegate+Dopamine.h
//  Pods
//
//  Created by Akash Desai on 8/15/17.
//
//


#ifndef UIApplicationDelegate_Dopamine_h
#define UIApplicationDelegate_Dopamine_h

@interface DopamineAppDelegate : NSObject

+ (void) enhanceSelectors: (BOOL)enable;
- (void) reinforced_applicationDidBecomeActive:(UIApplication*)application;
- (BOOL) reinforced_application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;

@end

#endif /* UIApplicationDelegate_Dopamine_h */
