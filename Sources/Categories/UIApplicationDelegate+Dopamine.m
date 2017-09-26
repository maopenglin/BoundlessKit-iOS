//
//  UIApplicationDelegate+Dopamine.m
//  Pods
//
//  Created by Akash Desai on 8/15/17.
//
//


#import <UIApplicationDelegate+Dopamine.h>

#import <DopamineKit/DopamineKit-Swift.h>
#import <SwizzleHelper.h>

@implementation DopamineAppDelegate

+ (void) swizzleSelectors {
    [SwizzleHelper injectSelector:[DopamineAppDelegate class] :@selector(swizzled_setDelegate:) :[UIApplication class] :@selector(setDelegate:)];
}

//+ (void) dopamineLoadedTagSelector {}

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
    
    Class swizzledClass = [DopamineAppDelegate class];
    delegateClass = [SwizzleHelper getClassWithProtocolInHierarchy:[delegate class] :@protocol(UIApplicationDelegate)];
    delegateSubclasses = [SwizzleHelper ClassGetSubclasses:delegateClass];
    
    // Application state
    //
    [SwizzleHelper injectToProperClass :@selector(swizzled_applicationDidBecomeActive:) :@selector(applicationDidBecomeActive:) :delegateSubclasses :swizzledClass :delegateClass ];
    [SwizzleHelper injectToProperClass :@selector(swizzled_applicationWillResignActive:) :@selector(applicationWillResignActive:) :delegateSubclasses :swizzledClass :delegateClass ];
    
    [self swizzled_setDelegate:delegate];
}

// Application State Swizzles

static NSDate *lastActive;

- (void) swizzled_applicationDidBecomeActive:(UIApplication*)application {
    lastActive = [[NSDate alloc] init];
    double recordedUTC = [lastActive timeIntervalSince1970] * 1000;
    
    [DopamineKit track:@"appFocus" metaData:@{@"tag":@"becomeActive",
                                              @"id": [NSNumber numberWithDouble:recordedUTC]}];

#ifdef DEBUG
    [VisualizerAPI promptPairing];
#endif
    
    if ([self respondsToSelector:@selector(swizzled_applicationDidBecomeActive:)])
        [self swizzled_applicationDidBecomeActive:application];
}

- (void) swizzled_applicationWillResignActive:(UIApplication*)application {
    NSDate *now = [[NSDate alloc] init];
    double recordedUTC = [now timeIntervalSince1970] * 1000;
    double millisActive = (lastActive) ? [now timeIntervalSinceDate:lastActive] : 0;
    [DopamineKit track:@"appFocus" metaData:@{@"tag":@"resignActive",
                                              @"id": [NSNumber numberWithDouble:recordedUTC],
                                              @"millisActive": [NSNumber numberWithDouble:millisActive]
                                              }];
    
    if ([self respondsToSelector:@selector(swizzled_applicationWillResignActive:)])
        [self swizzled_applicationWillResignActive:application];
}

@end
