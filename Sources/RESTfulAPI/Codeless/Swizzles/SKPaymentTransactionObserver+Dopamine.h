//
//  SKPaymentTransactionObserver+Dopamine.h
//  Pods
//
//  Created by Akash Desai on 9/21/17.
//
//


#ifndef SKPaymentTransactionObserver_Dopamine_h
#define SKPaymentTransactionObserver_Dopamine_h

#import <StoreKit/StoreKit.h>

@interface DopaminePaymentTransactionObserver : NSObject
+ (void) swizzleSelectors: (BOOL)enable;
@end

#endif /* SKPaymentTransactionObserver_Dopamine_h */
