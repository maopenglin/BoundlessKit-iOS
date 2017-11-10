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

- (void) swizzled_applicationDidBecomeActive:(UIApplication*)application {
    if ([self respondsToSelector:@selector(swizzled_applicationDidBecomeActive:)])
        [self swizzled_applicationDidBecomeActive:application];
    
    if ([[DopeConfig shared] applicationState]) {
        [DopamineKit track:@"UIApplicationDelegate" metaData:@{@"tag":@"didBecomeActive",
                                                               @"classname": NSStringFromClass([self class]),
                                                               @"time": [DopeTracking trackStartTimeFor:[self description]]
                                                               }];
    }
    
    if ([[DopeConfig shared] locationObservations]) {
//        [DopeLocation getLocation:true];
//        [DopeLocation onfocus:true];
//        (void)[DopeLocation shared];
        (void)[DopeLocation shared];
    }

#ifdef DEBUG
    [VisualizerAPI promptPairing];
#endif
    [[VisualizerAPI shared] retrieveRewards];
    
}

- (void) swizzled_applicationWillResignActive:(UIApplication*)application {
    if ([[DopeConfig shared] applicationState]) {
        [DopamineKit track:@"UIApplicationDelegate" metaData:@{@"tag":@"willResignActive",
                                                               @"time": [DopeTracking timeTrackedFor:[self description]]
                                                               }];
    }
    
//    if ([[DopeConfig shared] locationObservations]) {
//        [DopeLocation onfocus:false];
//    }
    
    if ([self respondsToSelector:@selector(swizzled_applicationWillResignActive:)])
        [self swizzled_applicationWillResignActive:application];
}

@end
