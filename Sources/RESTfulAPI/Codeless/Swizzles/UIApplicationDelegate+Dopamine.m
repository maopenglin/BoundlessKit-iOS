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
            [SwizzleHelper injectToProperClass :@selector(actionTrack_applicationWillResignActive:) :@selector(applicationWillResignActive:) :delegateSubclasses :enhancedClass :delegateClass ];
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
    [SelectorReinforcement recordActionForSenderInstance: nil targetInstance:self action:@selector(application:didFinishLaunchingWithOptions:)];
    
    if ([self respondsToSelector:@selector(enhanced_application:didFinishLaunchingWithOptions:)]) {
        return [self enhanced_application:application didFinishLaunchingWithOptions:launchOptions];
    } else {
        return true;
    }
}

- (void) enhanced_applicationWillTerminate:(UIApplication *)application {
    [SelectorReinforcement recordActionForSenderInstance: nil targetInstance:self action:@selector(applicationWillTerminate:)];
    
    if ([self respondsToSelector:@selector(enhanced_applicationWillTerminate:)]) {
        [self enhanced_applicationWillTerminate:application];
    }
}

- (void) enhanced_applicationDidBecomeActive:(UIApplication*)application {
    if ([self respondsToSelector:@selector(enhanced_applicationDidBecomeActive:)])
        [self enhanced_applicationDidBecomeActive:application];
    
//    [CodelessAPI bootWithCompletion:^{}];
    [SelectorReinforcement recordActionForSenderInstance: nil targetInstance:self action:@selector(applicationDidBecomeActive:)];
}

- (void) actionTrack_applicationWillResignActive:(UIApplication*)application {
    [SelectorReinforcement recordActionForSenderInstance: nil targetInstance:self action:@selector(applicationWillResignActive:)];
    
    if ([self respondsToSelector:@selector(actionTrack_applicationWillResignActive:)])
        [self actionTrack_applicationWillResignActive:application];
}

- (BOOL) reinforcedAction_application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [SelectorReinforcement attemptReinforcementWithSenderInstance:nil targetInstance:self action:@selector(application:didFinishLaunchingWithOptions:)];
    if ([self respondsToSelector:@selector(reinforcedAction_application:didFinishLaunchingWithOptions:)]) {
        return [self reinforcedAction_application:application didFinishLaunchingWithOptions:launchOptions];
    } else {
        return true;
    }
}

- (void) reinforcedAction_applicationDidBecomeActive:(UIApplication*)application {
    if ([self respondsToSelector:@selector(reinforcedAction_applicationDidBecomeActive:)])
        [self reinforcedAction_applicationDidBecomeActive:application];
    
    [SelectorReinforcement attemptReinforcementWithSenderInstance:nil targetInstance:self action:@selector(applicationDidBecomeActive:)];
}

@end
