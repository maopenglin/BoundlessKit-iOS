//
//  BMMethodSwizzling.m
//  Pods
//
//  Created by Akash Desai on 6/16/17.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#import <BoundlessKit/BoundlessKit-Swift.h>
#import <SwizzleHelper.h>
#import <UIApplicationDelegate+Boundless.h>
#import <UIApplication+Boundless.h>
#import <UIViewController+Boundless.h>
#import <UITapGestureRecognizer+Boundless.h>
#import <SKPaymentTransactionObserver+Boundless.h>
#import <UICollectionViewDelegate+Boundless.h>

@implementation UIApplication (Boundless)

+ (void) load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        // Swizzle - UIApplication
        [BoundlessApp swizzleSelectors];
        
        // Swizzle - UIApplicationDelegate
        [BoundlessAppDelegate swizzleSelectors];
        
        // Swizzle - UIViewController
        [BoundlessViewController swizzleSelectors];
        
        // Swizzle - UITapGestureRecognizer
        [BoundlessTapGestureRecognizer swizzleSelectors];
        
        // Swizzle - SKPaymentTransactionObserver
        [BoundlessPaymentTransactionObserver swizzleSelectors];
        
        // Swizzle - UICollectionViewController
        [BoundlessCollectionViewDelegate swizzleSelectors];
        
    });
}

@end

