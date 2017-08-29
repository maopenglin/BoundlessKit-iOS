//
//  UIWindow+Dopamine.m
//  Pods
//
//  Created by Akash Desai on 8/29/17.
//
//


#import <UIWindow+Dopamine.h>

#import <DopamineKit/DopamineKit-Swift.h>
#import <SwizzleHelper.h>

@implementation DopamineWindow

static UIView* _initialView;
static CGPoint previousTouchPosition1;
static CGPoint previousTouchPosition2;
static CGPoint startTouchPosition1;
static CGPoint startTouchPosition2;
static uint64_t startTouchTime;
static CGFloat ZOOM_DRAG_MIN = 30;
static CGFloat SWIPE_DRAG_HORIZ_MIN = 15;

+ (void) swizzleSelectors {
    [SwizzleHelper injectSelector:[DopamineWindow class] :@selector(swizzled_sendEvent:) :[UIWindow class] :@selector(sendEvent:)];
}

-(void) swizzled_sendEvent: (UIEvent *) event {
    for (UITouch *touch in event.allTouches){
        if (touch.phase == UITouchPhaseBegan){
            // TO-DO: ensure view responds to the event, otherwise get superviews
            [EventLogger logEventWithTouch:touch gestureName:@"tap"];
        } else if (touch.phase == UITouchPhaseEnded){
//            [EventLogger logEventWithType:[EventLogger EVENT_TYPE_TOUCHED] forObject:touch.view];
//            [Helper setLastTouch:touch];
            [Helper sendTouchWithTouch:touch];
            [Helper sendEventWithEvent:event];
            
        }
    }
    
//    /*
//     * Test code
//     */
//    
//    
//    NSSet<UITouch*>* allTouches = [event allTouches];
//    UITouch* touch = [allTouches anyObject];
//    UIView* touchView = [touch view];
//    
//    if (touch.phase == UITouchPhaseBegan) {
//        
//        if (touchView)
//            _initialView = touchView;
//        startTouchPosition1 = [touch locationInView:self];
//        startTouchTime = touch.timestamp;
//        
//        if ([allTouches count] > 1) {
//            startTouchPosition2 = [[[allTouches allObjects] objectAtIndex:1] locationInView:self];
//            previousTouchPosition1 = startTouchPosition1;
//            previousTouchPosition2 = startTouchPosition2;
//        }
//    }
//    
//    if (touch.phase == UITouchPhaseMoved) {
//        
//        if ([allTouches count] > 1) {
//            CGPoint currentTouchPosition1 = [[[allTouches allObjects] objectAtIndex:0] locationInView:self];
//            CGPoint currentTouchPosition2 = [[[allTouches allObjects] objectAtIndex:1] locationInView:self];
//            
//            CGFloat currentFingerDistance = hypot((currentTouchPosition1.x - currentTouchPosition2.x), (currentTouchPosition1.y - currentTouchPosition2.y));
//            CGFloat previousFingerDistance = hypot((previousTouchPosition1.x - previousTouchPosition2.x), (previousTouchPosition1.y - previousTouchPosition2.y));
//            if (fabs(currentFingerDistance - previousFingerDistance) > ZOOM_DRAG_MIN) {
//                //                NSNumber* movedDistance = [NSNumber numberWithFloat:currentFingerDistance - previousFingerDistance];
//                if (currentFingerDistance > previousFingerDistance) {
//                    //                          NSLog(@"zoom in");
//                    [EventLogger logEventWithTouch:touch gestureName:@"zoomIn"];
//                } else {
//                    //                          NSLog(@"zoom out");
//                    [EventLogger logEventWithTouch:touch gestureName:@"zoomOut"];
//                }
//            }
//        }
//    }
//    
//    if (touch.phase == UITouchPhaseEnded) {
//        CGPoint currentTouchPosition = [touch locationInView:self];
//        
//        // Check if it's a swipe
//        if (fabs(startTouchPosition1.x - currentTouchPosition.x) >= SWIPE_DRAG_HORIZ_MIN &&
//            fabs(startTouchPosition1.x - currentTouchPosition.x) > fabs(startTouchPosition1.y - currentTouchPosition.y) &&
//            touch.timestamp - startTouchTime < 0.7)
//        {
//            // It appears to be a swipe.
//            if (startTouchPosition1.x < currentTouchPosition.x) {
//                //                NSLog(@"swipe right");
//                [EventLogger logEventWithTouch:touch gestureName:@"swipeRight"];
//            } else {
//                //                NSLog(@"swipe left");
//                [EventLogger logEventWithTouch:touch gestureName:@"swipeLeft"];
//            }
//        } else {
//            //-- else, check if it's a single touch
//            if (touch.tapCount == 1) {
//                [EventLogger logEventWithTouch:touch gestureName:@"tap"];
//            }/* else if (touch.tapCount > 1) {
//              handle multi-touch
//              }
//              */
//        }
//        
//        startTouchPosition1 = CGPointMake(-1, -1);
//        _initialView = nil;
//    }
//    
//    if (touch.phase == UITouchPhaseCancelled) {
//        _initialView = nil;
//        //          NSLog(@"TOUCH CANCEL");
//    }
//
//    
//    /*
//     * /Test Code
//     */
    
    [self swizzled_sendEvent:event];
}

@end
