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

+ (void) enhanceSelectors: (BOOL) enable {
    @synchronized(self) {
        static BOOL didEnhance = false;
        if (enable ^ didEnhance) {
            didEnhance = !didEnhance;
            [SwizzleHelper injectSelector:[DopamineAppDelegate class] :@selector(enhanced_setDelegate:) :[UIApplication class] :@selector(setDelegate:)];
        }
    }
    [self enhanceDelegateClass:enable];
}


static Class delegateClass = nil;
static NSArray* delegateSubclasses = nil;
+ (void) enhanceDelegateClass:(BOOL) enable {
    if (delegateClass == nil) {
        return;
    }
    
    @synchronized(self) {
        static BOOL didEnhanceDelegate = false;
        if (enable ^ didEnhanceDelegate) {
            didEnhanceDelegate = !didEnhanceDelegate;
            
            // Application state
            //
            Class enhancedClass = [DopamineAppDelegate class];
            [SwizzleHelper injectToProperClass:@selector(enhanced_application:didFinishLaunchingWithOptions:) :@selector(application:didFinishLaunchingWithOptions:) :delegateSubclasses :enhancedClass :delegateClass];
//            [SwizzleHelper injectToProperClass:@selector(enhanced_applicationWillTerminate:) :@selector(applicationWillTerminate:) :delegateSubclasses :enhancedClass :delegateClass];
            [SwizzleHelper injectToProperClass :@selector(enhanced_applicationDidBecomeActive:) :@selector(applicationDidBecomeActive:) :delegateSubclasses :enhancedClass :delegateClass ];
            [SwizzleHelper injectToProperClass :@selector(enhanced_applicationWillResignActive:) :@selector(applicationWillResignActive:) :delegateSubclasses :enhancedClass :delegateClass ];
        }
    }
}

- (void) enhanced_setDelegate:(id<UIApplicationDelegate>)delegate {
    if (delegate && delegateClass == nil) {
        delegateClass = [SwizzleHelper getClassWithProtocolInHierarchy:[delegate class] :@protocol(UIApplicationDelegate)];
        delegateSubclasses = [SwizzleHelper ClassGetSubclasses:delegateClass];
        [DopamineAppDelegate enhanceDelegateClass:true];
    }
    
    [self enhanced_setDelegate:delegate];
}

// Application State Enhances

- (BOOL) enhanced_application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [CodelessAPI submitWithTargetInstance:self selector:@selector(application:didFinishLaunchingWithOptions:)];
    
    if ([self respondsToSelector:@selector(enhanced_application:didFinishLaunchingWithOptions:)]) {
        return [self enhanced_application:application didFinishLaunchingWithOptions:launchOptions];
    } else {
        return true;
    }
}

- (void) enhanced_applicationWillTerminate:(UIApplication *)application {
    [CodelessAPI submitWithTargetInstance:self selector:@selector(applicationWillTerminate:)];
    
    if ([self respondsToSelector:@selector(enhanced_applicationWillTerminate:)]) {
        [self enhanced_applicationWillTerminate:application];
    }
}

- (void) enhanced_applicationDidBecomeActive:(UIApplication*)application {
    if ([self respondsToSelector:@selector(enhanced_applicationDidBecomeActive:)])
        [self enhanced_applicationDidBecomeActive:application];
    
    [CodelessAPI bootWithCompletion:^{}];
    [CodelessAPI submitWithTargetInstance:self selector:@selector(applicationDidBecomeActive:)];
    
    if ([[DopamineConfiguration current] applicationState]) {
        [DopamineKit track:@"ApplicationState" metaData:@{@"tag":@"didBecomeActive",
                                                          @"classname": NSStringFromClass([self class]),
                                                          @"time": [DopeTimer trackStartTimeFor:[self description]]
                                                          }];
    }
    
}

- (void) enhanced_applicationWillResignActive:(UIApplication*)application {
    [CodelessAPI submitWithTargetInstance:self selector:@selector(applicationWillResignActive:)];
    
    if ([[DopamineConfiguration current] applicationState]) {
        [DopamineKit track:@"ApplicationState" metaData:@{@"tag":@"willResignActive",
                                                          @"classname": NSStringFromClass([self class]),
                                                          @"time": [DopeTimer timeTrackedFor:[self description]]
                                                          }];
    }
    
    if ([self respondsToSelector:@selector(enhanced_applicationWillResignActive:)])
        [self enhanced_applicationWillResignActive:application];
}

- (BOOL) reinforced_application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [SelectorReinforcement attemptReinforcementWithTarget:self action:@selector(application:didFinishLaunchingWithOptions:)];
    
    if ([self respondsToSelector:@selector(reinforced_application:didFinishLaunchingWithOptions:)]) {
        return [self reinforced_application:application didFinishLaunchingWithOptions:launchOptions];
    } else {
        return true;
    }
}

- (void) reinforced_applicationDidBecomeActive:(UIApplication*)application {
    if ([self respondsToSelector:@selector(reinforced_applicationDidBecomeActive:)])
        [self reinforced_applicationDidBecomeActive:application];
    
    [SelectorReinforcement attemptReinforcementWithTarget:self action:@selector(applicationDidBecomeActive:)];
}

@end
