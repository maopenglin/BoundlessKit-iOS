//
//  UIApplication+Dopamine.m
//  Pods
//
//  Created by Akash Desai on 8/15/17.
//
//


#import <UIApplication+Dopamine.h>

#import <DopamineKit/DopamineKit-Swift.h>
#import <SwizzleHelper.h>

@implementation DopamineApp

+ (void) sendActionsToDashboard: (BOOL) enable {
    @synchronized(self) {
        static BOOL didEnhance = false;
        if (enable ^ didEnhance) {
            didEnhance = !didEnhance;
            
            [SwizzleHelper injectSelector:[DopamineApp class] :@selector(enhanced_sendEvent:) :[UIApplication class] :@selector(sendEvent:)];
        }
    }
}

- (BOOL)dashboardIntegration_sendAction:(SEL)action to:(id)target from:(id)sender forEvent:(UIEvent *)event {
    
    if (action && target) {
        NSString *selectorName = NSStringFromSelector(action);
        
        // Sometimes this method proxies through to its internal method. We want to ignore those calls.
        if (![selectorName isEqualToString:@"_sendAction:withEvent:"]) {
            [DopamineSelector attemptIntegrationWithSenderInstance:sender targetInstance:target action:action];
        }
    }
    
    return [self dashboardIntegration_sendAction:action to:target from:sender forEvent:event];
}

@end
