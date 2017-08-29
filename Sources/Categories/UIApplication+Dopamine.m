//
//  UIApplicationDelegate+Dopamine.m
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
}

-(void) swizzled_sendEvent: (UIEvent *) event
{
    for (UITouch *touch in event.allTouches){
        if (touch.phase == UITouchPhaseBegan){
            // TO-DO: ensure view responds to the event, otherwise get superviews
            [EventLogger logEventWithTouch:touch completion:^{
            }];
        } else if (touch.phase == UITouchPhaseEnded){
//            [EventLogger logEventWithType:[EventLogger EVENT_TYPE_TOUCHED] forObject:touch.view];
//            [Helper setLastTouch:touch];
            [Helper sendTouchWithTouch:touch];
            [Helper sendEventWithEvent:event];
            
        }
    }
    [self swizzled_sendEvent:event];
}

@end
