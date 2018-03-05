//
//  UIApplication+Boundless.m
//  Pods
//
//  Created by Akash Desai on 8/15/17.
//
//


#import <UIApplication+Boundless.h>

#import <BoundlessKit/BoundlessKit-Swift.h>
#import <SwizzleHelper.h>

@implementation BoundlessApp

+ (void) swizzleSelectors {
    [SwizzleHelper injectSelector:[BoundlessApp class] :@selector(swizzled_sendEvent:) :[UIApplication class] :@selector(sendEvent:)];
    [SwizzleHelper injectSelector:[BoundlessApp class] :@selector(swizzled_sendAction:to:from:forEvent:) :[UIApplication class] :@selector(sendAction:to:from:forEvent:)];
}

-(void) swizzled_sendEvent: (UIEvent *) event {
    if (event) {
        UITouch* touch = event.allTouches.anyObject;
        if (touch != nil) {
            [CodelessAPI recordEventWithTouch:touch];
        }
    }

    if ([self respondsToSelector:@selector(swizzled_sendEvent:)])
        [self swizzled_sendEvent:event];
}

- (BOOL)swizzled_sendAction:(SEL)action to:(id)target from:(id)sender forEvent:(UIEvent *)event {
    
    if (action && target && sender) {
        NSString *selectorName = NSStringFromSelector(action);
        
        // Sometimes this method proxies through to its internal method. We want to ignore those calls.
        if (![selectorName isEqualToString:@"_sendAction:withEvent:"]) {
            [CodelessAPI recordActionWithApplication:self senderInstance:sender targetInstance:target selectorObj:action];
            
            if ([[[BoundlessConfiguration current] customEvents] objectForKey:[@[NSStringFromClass([sender class]), NSStringFromClass([target class]), selectorName] componentsJoinedByString:@"-"]]) {
                [BoundlessKit track:@"UIApplication" metaData:@{@"tag": @"sendAction",
                                                               @"sender": NSStringFromClass([sender class]),
                                                               @"target": NSStringFromClass([target class]),
                                                               @"selector": selectorName}
                 ];
            }
        }
    }
    
    return [self swizzled_sendAction:action to:target from:sender forEvent:event];
}

@end
