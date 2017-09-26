//
//  SKProductsRequest+Dopamine.m
//  Pods
//
//  Created by Akash Desai on 9/21/17.
//
//


#import <SKProductsRequest+Dopamine.h>

#import <DopamineKit/DopamineKit-Swift.h>
#import <SwizzleHelper.h>

@implementation DopamineProductsRequest

+ (void) swizzleSelectors {
    [SwizzleHelper injectSelector:[DopamineProductsRequest class] :@selector(swizzled_initWithProductIdentifiers:) :[SKProductsRequest class] :@selector(initWithProductIdentifiers:)];
}

- (instancetype)swizzled_initWithProductIdentifiers:(NSSet<NSString *> *)productIdentifiers {
    NSLog(@"Inside swizzled initWithProductIdentifiers params:%@", productIdentifiers);
    return [self swizzled_initWithProductIdentifiers:productIdentifiers];
}
    
//// Application State Swizzles
//
//- (void) swizzled_applicationDidBecomeActive:(UIApplication*)application {
//    [EventLogger logEventWithType:[EventLogger EVENT_TYPE_APP_FOCUS] withTag:@"becomeActive"];
//    
//    
//    if ([self respondsToSelector:@selector(swizzled_applicationDidBecomeActive:)])
//        [self swizzled_applicationDidBecomeActive:application];
//}
//
//- (void) swizzled_applicationWillResignActive:(UIApplication*)application {
//    [EventLogger logEventWithType:[EventLogger EVENT_TYPE_APP_FOCUS] withTag:@"resignActive"];
//    
//    if ([self respondsToSelector:@selector(swizzled_applicationWillResignActive:)])
//        [self swizzled_applicationWillResignActive:application];
//}

@end
