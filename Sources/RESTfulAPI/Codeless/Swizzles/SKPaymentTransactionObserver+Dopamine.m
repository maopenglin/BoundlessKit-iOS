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

+ (void) enhanceSelectors: (BOOL) enable {
    @synchronized(self) {
        static BOOL didEnhance = false;
        if (enable ^ didEnhance) {
            didEnhance = !didEnhance;
            [SwizzleHelper injectSelector:[DopaminePaymentTransactionObserver class] :@selector(enhanced_addTransactionObserver:) :[SKPaymentQueue class] :@selector(addTransactionObserver:)];
        }
    }
    
    [DopaminePaymentTransactionObserver enhanceObserverClass:enable];
}

static Class observerClass = nil;
static NSArray* observerSubclasses = nil;

+ (void) enhanceObserverClass: (BOOL) enable {
    if (observerClass == nil) {
        return;
    }
    
    @synchronized(self) {
        static BOOL didEnhanceObserver = false;
        if (enable ^ didEnhanceObserver) {
            didEnhanceObserver = !didEnhanceObserver;
            [SwizzleHelper injectToProperClass:@selector(enhanced_paymentQueue:updatedTransactions:) :@selector(paymentQueue:updatedTransactions:) :observerSubclasses :[DopaminePaymentTransactionObserver self] :observerClass];
        }
    }
}

- (void)enhanced_addTransactionObserver:(id<SKPaymentTransactionObserver>)observer {
    if (observer && observerClass == nil) {
        observerClass = [SwizzleHelper getClassWithProtocolInHierarchy:[observer class] :@protocol(SKPaymentTransactionObserver)];
        observerSubclasses = [SwizzleHelper ClassGetSubclasses:observerClass];
        [DopaminePaymentTransactionObserver enhanceObserverClass: true];
    }
    
    [self enhanced_addTransactionObserver:observer];
}

- (void)enhanced_paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    
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
    
    if ([self respondsToSelector:@selector(enhanced_paymentQueue:updatedTransactions:)]) {
        [self enhanced_paymentQueue:queue updatedTransactions:transactions];
    }
}

@end
