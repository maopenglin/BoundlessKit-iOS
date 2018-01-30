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

+ (void) swizzleSelectors: (BOOL) enable {
    @synchronized(self) {
        static BOOL didSwizzle = false;
        if (enable ^ didSwizzle) {
            didSwizzle = !didSwizzle;
            [SwizzleHelper injectSelector:[DopamineAppDelegate class] :@selector(swizzled_setDelegate:) :[UIApplication class] :@selector(setDelegate:)];
        }
    }
    [self swizzleDelegateClass:enable];
}


static Class delegateClass = nil;
static NSArray* delegateSubclasses = nil;
+ (void) swizzleDelegateClass:(BOOL) enable {
    if (delegateClass == nil) {
        return;
    }
    
    @synchronized(self) {
        static BOOL didSwizzleDelegate = false;
        if (enable ^ didSwizzleDelegate) {
            didSwizzleDelegate = !didSwizzleDelegate;
            
            // Application state
            //
            Class swizzledClass = [DopamineAppDelegate class];
            [SwizzleHelper injectToProperClass:@selector(swizzled_application:didFinishLaunchingWithOptions:) :@selector(application:didFinishLaunchingWithOptions:) :delegateSubclasses :swizzledClass :delegateClass];
//            [SwizzleHelper injectToProperClass:@selector(swizzled_applicationWillTerminate:) :@selector(applicationWillTerminate:) :delegateSubclasses :swizzledClass :delegateClass];
            [SwizzleHelper injectToProperClass :@selector(swizzled_applicationDidBecomeActive:) :@selector(applicationDidBecomeActive:) :delegateSubclasses :swizzledClass :delegateClass ];
            [SwizzleHelper injectToProperClass :@selector(swizzled_applicationWillResignActive:) :@selector(applicationWillResignActive:) :delegateSubclasses :swizzledClass :delegateClass ];
        }
    }
}

- (void) swizzled_setDelegate:(id<UIApplicationDelegate>)delegate {
    if (delegate && delegateClass == nil) {
        delegateClass = [SwizzleHelper getClassWithProtocolInHierarchy:[delegate class] :@protocol(UIApplicationDelegate)];
        delegateSubclasses = [SwizzleHelper ClassGetSubclasses:delegateClass];
        [DopamineAppDelegate swizzleDelegateClass:true];
    }
    
    [self swizzled_setDelegate:delegate];
}

// Application State Swizzles

- (BOOL) swizzled_application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [CodelessAPI submitWithTarget:self selector:@selector(application:didFinishLaunchingWithOptions:)];
    
    if ([self respondsToSelector:@selector(swizzled_application:didFinishLaunchingWithOptions:)]) {
        return [self swizzled_application:application didFinishLaunchingWithOptions:launchOptions];
    } else {
        return true;
    }
}

- (void) swizzled_applicationWillTerminate:(UIApplication *)application {
    [CodelessAPI submitWithTarget:self selector:@selector(applicationWillTerminate:)];
    
    if ([self respondsToSelector:@selector(swizzled_applicationWillTerminate:)]) {
        [self swizzled_applicationWillTerminate:application];
    }
}

- (void) swizzled_applicationDidBecomeActive:(UIApplication*)application {
    if ([self respondsToSelector:@selector(swizzled_applicationDidBecomeActive:)])
        [self swizzled_applicationDidBecomeActive:application];
    
    [CodelessAPI bootWithCompletion:^{}];
    [CodelessAPI submitWithTarget:self selector:@selector(applicationDidBecomeActive:)];
    
    if ([[DopamineConfiguration current] applicationState]) {
        [DopamineKit track:@"ApplicationState" metaData:@{@"tag":@"didBecomeActive",
                                                          @"classname": NSStringFromClass([self class]),
                                                          @"time": [DopeTimer trackStartTimeFor:[self description]]
                                                          }];
    }
    
}

- (void) swizzled_applicationWillResignActive:(UIApplication*)application {
    [CodelessAPI submitWithTarget:self selector:@selector(applicationWillResignActive:)];
    
    if ([[DopamineConfiguration current] applicationState]) {
        [DopamineKit track:@"ApplicationState" metaData:@{@"tag":@"willResignActive",
                                                          @"classname": NSStringFromClass([self class]),
                                                          @"time": [DopeTimer timeTrackedFor:[self description]]
                                                          }];
    }
    
    if ([self respondsToSelector:@selector(swizzled_applicationWillResignActive:)])
        [self swizzled_applicationWillResignActive:application];
}

@end
