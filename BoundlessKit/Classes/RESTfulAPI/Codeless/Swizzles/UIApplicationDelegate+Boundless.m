//
//  UIApplicationDelegate+Boundless.m
//  Pods
//
//  Created by Akash Desai on 8/15/17.
//
//


#import <UIApplicationDelegate+Boundless.h>

#import <BoundlessKit/BoundlessKit-Swift.h>
#import <SwizzleHelper.h>

@implementation BoundlessAppDelegate

+ (void) swizzleSelectors {
    [SwizzleHelper injectSelector:[BoundlessAppDelegate class] :@selector(swizzled_setDelegate:) :[UIApplication class] :@selector(setDelegate:)];
}

static Class delegateClass = nil;

// Store an array of all UIAppDelegate subclasses to iterate over in cases where UIAppDelegate swizzled methods are not overriden in main AppDelegate
// But rather in one of the subclasses
static NSArray* delegateSubclasses = nil;

+ (Class) delegateClass {
    return delegateClass;
}

- (void) swizzled_setDelegate:(id<UIApplicationDelegate>)delegate {
    if (delegateClass) {
        [self swizzled_setDelegate:delegate];
        return;
    }
    
    Class swizzledClass = [BoundlessAppDelegate class];
    delegateClass = [SwizzleHelper getClassWithProtocolInHierarchy:[delegate class] :@protocol(UIApplicationDelegate)];
    delegateSubclasses = [SwizzleHelper ClassGetSubclasses:delegateClass];
    
    // Application state
    //
    [SwizzleHelper injectToProperClass:@selector(swizzled_application:didFinishLaunchingWithOptions:) :@selector(application:didFinishLaunchingWithOptions:) :delegateSubclasses :swizzledClass :delegateClass];
    [SwizzleHelper injectToProperClass :@selector(swizzled_applicationDidBecomeActive:) :@selector(applicationDidBecomeActive:) :delegateSubclasses :swizzledClass :delegateClass ];
    [SwizzleHelper injectToProperClass :@selector(swizzled_applicationWillResignActive:) :@selector(applicationWillResignActive:) :delegateSubclasses :swizzledClass :delegateClass ];
    
    [self swizzled_setDelegate:delegate];
}

// Application State Swizzles

- (BOOL) swizzled_application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [CodelessAPI recordAppEventWithName:@"appLaunch"];
    
    if ([self respondsToSelector:@selector(swizzled_application:didFinishLaunchingWithOptions:)]) {
        return [self swizzled_application:application didFinishLaunchingWithOptions:launchOptions];
    } else {
        return true;
    }
}

- (void) swizzled_applicationWillTerminate:(UIApplication *)application {
    [CodelessAPI recordAppEventWithName:@"appTerminate"];
    
    if ([self respondsToSelector:@selector(swizzled_applicationWillTerminate:)]) {
        [self swizzled_applicationWillTerminate:application];
    }
}

- (void) swizzled_applicationDidBecomeActive:(UIApplication*)application {
    if ([self respondsToSelector:@selector(swizzled_applicationDidBecomeActive:)])
        [self swizzled_applicationDidBecomeActive:application];
    
    [CodelessAPI bootWithCompletion:^{}];
    [CodelessAPI recordAppEventWithName:@"appActive"];
    
    if ([[BoundlessConfiguration current] applicationState]) {
        [BoundlessKit track:@"ApplicationState" metaData:@{@"tag":@"didBecomeActive",
                                                          @"classname": NSStringFromClass([self class]),
                                                          @"time": [BoundlessTimer trackStartTimeFor:[self description]]
                                                          }];
    }
    
}

- (void) swizzled_applicationWillResignActive:(UIApplication*)application {
    [CodelessAPI recordAppEventWithName:@"appInactive"];
    
    if ([[BoundlessConfiguration current] applicationState]) {
        [BoundlessKit track:@"ApplicationState" metaData:@{@"tag":@"willResignActive",
                                                          @"classname": NSStringFromClass([self class]),
                                                          @"time": [BoundlessTimer timeTrackedFor:[self description]]
                                                          }];
    }
    
    if ([self respondsToSelector:@selector(swizzled_applicationWillResignActive:)])
        [self swizzled_applicationWillResignActive:application];
}

@end
