//
//  DTMethodSwizzling.m
//  Pods
//
//  Created by Akash Desai on 6/16/17.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#import <DopamineKit/DopamineKit-Swift.h>
#import <SwizzleHelper.h>
#import <UIApplicationDelegate+Dopamine.h>
#import <UIApplication+Dopamine.h>
#import <UIWindow+Dopamine.h>
#import <UIViewController+Dopamine.h>
#import <SKPaymentTransactionObserver+Dopamine.h>

@implementation UIApplication (Dopamine)

+ (void) load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        // Swizzle - UIApplication
        [DopamineApp swizzleSelectors];
        
        // Swizzle - UIApplicationDelegate
        [DopamineAppDelegate swizzleSelectors];
        
//        // Swizzle - UIWindow
//        [DopamineWindow swizzleSelectors];
        
        // Swizzle - UIViewController
        [DopamineViewController swizzleSelectors];
        
        // Swizzle - DopaminePaymentTransactionObserver
        [DopaminePaymentTransactionObserver swizzleSelectors];
        
    });
}

@end

