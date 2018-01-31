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

#import "DopamineKit.h"
#import "ASIdentifierManager+ASIdentifierManagerHelper.h"
#import "DTMethodSwizzling.h"
#import "NSObject+Dopamine.h"
#import "SKPaymentTransactionObserver+Dopamine.h"
#import "SwizzleHelper.h"
#import "UIApplication+Dopamine.h"
#import "UIApplicationDelegate+Dopamine.h"
#import "UICollectionViewDelegate+Dopamine.h"
#import "UITapGestureRecognizer+Dopamine.h"
#import "UIViewController+Dopamine.h"

FOUNDATION_EXPORT double DopamineKitVersionNumber;
FOUNDATION_EXPORT const unsigned char DopamineKitVersionString[];

