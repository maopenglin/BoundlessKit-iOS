//
//  SKPaymentTransactionObserver+Dopamine.m
//  Pods
//
//  Created by Akash Desai on 9/21/17.
//
//


#import <SKPaymentTransactionObserver+Dopamine.h>

#import <DopamineKit/DopamineKit-Swift.h>
#import <SwizzleHelper.h>

@implementation DopaminePaymentTransactionObserver

+ (void) swizzleSelectors {
    [SwizzleHelper injectSelector:[DopaminePaymentTransactionObserver class] :@selector(swizzled_addTransactionObserver:) :[SKPaymentQueue class] :@selector(addTransactionObserver:)];
}

static Class observerClass = nil;
static NSArray* observerSubclasses = nil;

+ (Class) observerClass {
    return observerClass;
}

- (void)swizzled_addTransactionObserver:(id<SKPaymentTransactionObserver>)observer {
    if (observerClass) {
        [self swizzled_addTransactionObserver:observer];
        return;
    }
    
    Class swizzledClass = [DopaminePaymentTransactionObserver class];
    observerClass = [SwizzleHelper getClassWithProtocolInHierarchy:[observer class] :@protocol(SKPaymentTransactionObserver)];
    observerSubclasses = [SwizzleHelper ClassGetSubclasses:observerClass];
    
    [SwizzleHelper injectToProperClass:@selector(swizzled_paymentQueue:updatedTransactions:) :@selector(paymentQueue:updatedTransactions:) :observerSubclasses :swizzledClass :observerClass];
    
    [self swizzled_addTransactionObserver:observer];
}

- (void)swizzled_paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    NSLog(@"Inside swizzled_paymentQueue:updatedtransactions with following transactions:");
    for (SKPaymentTransaction* transaction in transactions) {
        NSString* stateName;
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                stateName = @"Purchased";
                break;
                
            case SKPaymentTransactionStateFailed:
                stateName = @"Failed";
                break;
                
            case SKPaymentTransactionStateRestored:
                stateName = @"Restored";
                break;
                
            case SKPaymentTransactionStateDeferred:
                stateName = @"Deferred";
                break;
                
            case SKPaymentTransactionStatePurchasing:
                stateName = @"Purchasing";
                break;
                
            default:
                stateName = @"unknown";
                break;
        }
        NSLog(@"\tTransaction <%@> has state <%@>", transaction.payment.productIdentifier, stateName);
    }
    
    if ([self respondsToSelector:@selector(swizzled_paymentQueue:updatedTransactions:)]) {
        [self swizzled_paymentQueue:queue updatedTransactions:transactions];
    }
}

@end
