//
//  UIApplication+Boundless.m
//  Pods
//
//  Created by Akash Desai on 8/15/17.
//
//


#import <UIApplication+Boundless.h>

@implementation BoundlessApp

- (BOOL)notifyMessages__sendAction:(SEL)action to:(id)target from:(id)sender forEvent:(UIEvent *)event {
    
    if (action && target) {
        NSString *selectorName = NSStringFromSelector(action);
        
        // Sometimes this method proxies through to its internal method. We want to ignore those calls.
        if (![selectorName isEqualToString:@"_sendAction:withEvent:"]) {
//            [InstanceSelectorNotificationCenterObjc postMessageWithClassType:[target class] selector:action];
        }
    }
    
    return [self notifyMessages__sendAction:action to:target from:sender forEvent:event];
}

@end
