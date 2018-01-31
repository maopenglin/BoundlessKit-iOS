//
//  DTMethodSwizzling.m
//  Pods
//
//  Created by Akash Desai on 6/16/17.
//
//

#import <DTMethodSwizzling.h>

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#import <DopamineKit/DopamineKit-Swift.h>
#import <SwizzleHelper.h>
#import <UIApplicationDelegate+Dopamine.h>
#import <UIApplication+Dopamine.h>
#import <UIViewController+Dopamine.h>
#import <UITapGestureRecognizer+Dopamine.h>
#import <SKPaymentTransactionObserver+Dopamine.h>
#import <UICollectionViewDelegate+Dopamine.h>

@implementation DTMethodSwizzling

+ (void) load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleSelectedMethods];
    });
}

+ (void) swizzleSelectedMethods {
    NSString *defaultsKey = [NSString stringWithFormat:@"disableStandardSwizzling"];
    BOOL shouldSwizzle = ![[NSUserDefaults dopamine] boolForKey: defaultsKey];
    NSLog(@"Value for %@:%d", defaultsKey, !shouldSwizzle);
    
    // Swizzle - UIApplication
    [DopamineApp swizzleSelectors: shouldSwizzle];
    
    // Swizzle - UIApplicationDelegate
    [DopamineAppDelegate swizzleSelectors: shouldSwizzle];
    
    // Swizzle - UIViewController
    [DopamineViewController swizzleSelectors: shouldSwizzle];
    
    // Swizzle - UITapGestureRecognizer
    [DopamineTapGestureRecognizer swizzleSelectors: shouldSwizzle];
    
    // Swizzle - SKPaymentTransactionObserver
    [DopaminePaymentTransactionObserver swizzleSelectors: shouldSwizzle];
    
    // Swizzle - UICollectionViewController
    [DopamineCollectionViewDelegate swizzleSelectors: shouldSwizzle];
    
}

@end

