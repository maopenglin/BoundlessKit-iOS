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

+ (void) enhanceSelectors: (BOOL) enable {
    @synchronized(self) {
        static BOOL didEnhance = false;
        if (enable ^ didEnhance) {
            didEnhance = !didEnhance;
            
            [SwizzleHelper injectSelector:[DopamineApp class] :@selector(enhanced_sendEvent:) :[UIApplication class] :@selector(sendEvent:)];
            [SwizzleHelper injectSelector:[DopamineApp class] :@selector(enhanced_sendAction:to:from:forEvent:) :[UIApplication class] :@selector(sendAction:to:from:forEvent:)];
        }
    }
}

-(void) enhanced_sendEvent: (UIEvent *) event {
    if (event) {
        UITouch* touch = event.allTouches.anyObject;
        [CodelessReinforcement setLastTouch: touch];
    }

    if ([self respondsToSelector:@selector(enhanced_sendEvent:)])
        [self enhanced_sendEvent:event];
}

- (BOOL)enhanced_sendAction:(SEL)action to:(id)target from:(id)sender forEvent:(UIEvent *)event {
    
    if (action && target) {
        NSString *selectorName = NSStringFromSelector(action);
        
        // Sometimes this method proxies through to its internal method. We want to ignore those calls.
        if (![selectorName isEqualToString:@"_sendAction:withEvent:"]) {
            [SelectorReinforcement integrationModeSubmitWithSenderInstance:sender targetInstance:target action:action];
        }
    }
    
    return [self enhanced_sendAction:action to:target from:sender forEvent:event];
}

@end
