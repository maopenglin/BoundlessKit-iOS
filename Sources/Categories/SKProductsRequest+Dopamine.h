//
//  SKProductsRequest+Dopamine.h
//  Pods
//
//  Created by Akash Desai on 9/21/17.
//
//


#ifndef SKProductsRequest_Dopamine_h
#define SKProductsRequest_Dopamine_h

#import <StoreKit/StoreKit.h>

@interface DopamineProductsRequest : SKProductsRequest
+ (void) swizzleSelectors;
@end

#endif /* SKProductsRequest_Dopamine_h */
