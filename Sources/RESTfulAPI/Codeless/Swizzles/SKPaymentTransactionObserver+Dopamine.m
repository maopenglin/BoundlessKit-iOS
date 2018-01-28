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

+ (void) swizzleSelectors: (BOOL) enable {
    @synchronized(self) {
        static BOOL didSwizzle = false;
        if (enable ^ didSwizzle) {
            didSwizzle = !didSwizzle;
            [SwizzleHelper injectSelector:[DopaminePaymentTransactionObserver class] :@selector(swizzled_addTransactionObserver:) :[SKPaymentQueue class] :@selector(addTransactionObserver:)];
        }
    }
    
    [DopaminePaymentTransactionObserver swizzleObserverClass:enable];
}

static Class observerClass = nil;
static NSArray* observerSubclasses = nil;

+ (void) swizzleObserverClass: (BOOL) enable {
    if (observerClass == nil) {
        return;
    }
    
    @synchronized(self) {
        static BOOL didSwizzleObserver = false;
        if (enable ^ didSwizzleObserver) {
            didSwizzleObserver = !didSwizzleObserver;
            [SwizzleHelper injectToProperClass:@selector(swizzled_paymentQueue:updatedTransactions:) :@selector(paymentQueue:updatedTransactions:) :observerSubclasses :[DopaminePaymentTransactionObserver self] :observerClass];
        }
    }
}

- (void)swizzled_addTransactionObserver:(id<SKPaymentTransactionObserver>)observer {
    if (observer && observerClass == nil) {
        observerClass = [SwizzleHelper getClassWithProtocolInHierarchy:[observer class] :@protocol(SKPaymentTransactionObserver)];
        observerSubclasses = [SwizzleHelper ClassGetSubclasses:observerClass];
        [DopaminePaymentTransactionObserver swizzleObserverClass: true];
    }
    
    [self swizzled_addTransactionObserver:observer];
}

- (void)swizzled_paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    
    if (transactions && [[DopamineConfiguration current] storekitObservations]) {
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
            [DopamineKit track:@"SKPaymentTransactionObserver" metaData:@{@"tag": @"updatedTransactions",
                                                                          @"classname": NSStringFromClass([self class]),
                                                                          @"productID": transaction.payment.productIdentifier,
                                                                          @"quantity": [NSNumber numberWithInteger:transaction.payment.quantity],
                                                                          @"transactionState": stateName}];
        }
    }
    
    if ([self respondsToSelector:@selector(swizzled_paymentQueue:updatedTransactions:)]) {
        [self swizzled_paymentQueue:queue updatedTransactions:transactions];
    }
}

@end
