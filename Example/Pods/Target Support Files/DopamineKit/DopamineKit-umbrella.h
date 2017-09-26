#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "SKPaymentTransactionObserver+Dopamine.h"
#import "UIApplication+Dopamine.h"
#import "UIApplicationDelegate+Dopamine.h"
#import "UIViewController+Dopamine.h"
#import "UIWindow+Dopamine.h"
#import "DopamineKit.h"
#import "SwizzleHelper.h"

FOUNDATION_EXPORT double DopamineKitVersionNumber;
FOUNDATION_EXPORT const unsigned char DopamineKitVersionString[];

