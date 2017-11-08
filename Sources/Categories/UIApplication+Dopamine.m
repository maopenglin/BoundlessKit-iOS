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

+ (void) swizzleSelectors {
    [SwizzleHelper injectSelector:[DopamineApp class] :@selector(swizzled_sendEvent:) :[UIApplication class] :@selector(sendEvent:)];
    [SwizzleHelper injectSelector:[DopamineApp class] :@selector(swizzled_sendAction:to:from:forEvent:) :[UIApplication class] :@selector(sendAction:to:from:forEvent:)];
}

-(void) swizzled_sendEvent: (UIEvent *) event {
    UITouch* touch = event.allTouches.anyObject;
    if (touch != nil) {
        CGPoint local = [touch locationInView:[touch view]];
        Helper.lastTouchLocationInUIWindow = [[touch view] convertPoint:local toView:nil];
        [VisualizerAPI recordEventWithTouch:touch];
    }

    if ([self respondsToSelector:@selector(swizzled_sendEvent:)])
        [self swizzled_sendEvent:event];
}

- (BOOL)swizzled_sendAction:(SEL)action to:(id)target from:(id)sender forEvent:(UIEvent *)event {
    if ([[DopeConfig shared] applicationState]) {
        NSString *selectorName = NSStringFromSelector(action);
        // Sometimes this method proxies through to its internal method. We want to ignore those calls.
        if (![selectorName isEqualToString:@"_sendAction:withEvent:"]) {
            [DopamineKit track:@"UIApplication" metaData:@{@"tag": @"sendAction",
                                                           @"sender": NSStringFromClass([sender class]),
                                                           @"target": NSStringFromClass([target class]),
                                                           @"selector": selectorName}
             ];
            [VisualizerAPI recordActionWithSenderInstance:sender targetInstance:target selectorObj:action event:event];
        }
    }
    
    return [self swizzled_sendAction:action to:target from:sender forEvent:event];
}

@end
