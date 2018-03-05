//
//  SKPaymentTransactionObserver+Boundless.h
//  Pods
//
//  Created by Akash Desai on 9/21/17.
//
//


#ifndef SKPaymentTransactionObserver_Boundless_h
#define SKPaymentTransactionObserver_Boundless_h

#import <StoreKit/StoreKit.h>

@interface BoundlessPaymentTransactionObserver : NSObject
+ (void) swizzleSelectors;
@end

#endif /* SKPaymentTransactionObserver_Boundless_h */
