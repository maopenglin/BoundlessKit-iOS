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
    [SwizzleHelper injectSelector:[DopamineApp class] :@selector(swizzled_sendAction:to:from:forEvent:) :[UIApplication class] :@selector(sendAction:to:from:forEvent:)];
    [SwizzleHelper injectSelector:[DopamineApp class] :@selector(swizzled_sendEvent:) :[UIApplication class] :@selector(sendEvent:)];
}

//static NSUInteger firstTouchHash;
//static uint64_t startTouchTime;
//static CGPoint startTouchPosition1;
//static CGPoint startTouchPosition2;
//static CGFloat SWIPE_DRAG_MIN = 80;
//static CGFloat PINCH_MIN = 20;
//
-(void) swizzled_sendEvent: (UIEvent *) event {
    UITouch* touch = event.allTouches.anyObject;
    if (touch != nil) {
        CGPoint local = [touch locationInView:[touch view]];
        Helper.lastTouchLocationInUIWindow = [[touch view] convertPoint:local toView:nil];
    }
    
    
//    if (event.allTouches.count == 1) {
//        UITouch *touch = event.allTouches.anyObject;
//        
//        if (touch.phase == UITouchPhaseBegan) {
//            // could be pinch or swipe or drag or tap or hold
//            firstTouchHash = touch.hash;
//            
//            startTouchTime = [touch timestamp];
//            startTouchPosition1 = [touch locationInView:[touch view]];
//        } else if (touch.phase == UITouchPhaseEnded && touch.hash == firstTouchHash) {
//            // swipe or drag or tap or hold
//            
//            CGPoint currentTouchPosition = [touch locationInView:[touch view]];
//            double xDistance = fabs(startTouchPosition1.x - currentTouchPosition.x);
//            double yDistance = fabs(startTouchPosition1.y - currentTouchPosition.y);
//            
//            if (xDistance >= SWIPE_DRAG_MIN || yDistance >= SWIPE_DRAG_MIN) {
//                
//                NSString* swipeOrDrag = (touch.timestamp - startTouchTime < 1.0) ? @"Swipe" : @"Drag";
//                NSString* direction = (xDistance > yDistance) ?
//                    (currentTouchPosition.x > startTouchPosition1.x) ? @"right" : @"left"
//                    : (currentTouchPosition.y > startTouchPosition1.y) ? @"down" : @"up";
//                [DopamineKit track:@"UIApplication_sendEvent_touchEnded" metaData:@{@"touchType": swipeOrDrag,
//                                                                         @"direction": direction
//                                                                         }];
////                if (xDistance > yDistance) {
////                    if (currentTouchPosition.x > startTouchPosition1.x) {
////                        [DopamineKit track:@"UIApplication_sendEvent" metaData:@{@"touchType": [NSString stringWithFormat:@"%@ right", swipeOrDrag]}];
////                        [touchMetadata setValue:[NSString stringWithFormat:@"%@ right", swipeOrDrag] forKey:@"touchType"];
////                    } else {
////                        [touchMetadata setValue:[NSString stringWithFormat:@"%@ left", swipeOrDrag] forKey:@"touchType"];
////                    }
////                } else {
////                    if (currentTouchPosition.y > startTouchPosition1.y) {
////                        [touchMetadata setValue:[NSString stringWithFormat:@"%@ down", swipeOrDrag] forKey:@"touchType"];
////                    } else {
////                        [touchMetadata setValue:[NSString stringWithFormat:@"%@ up", swipeOrDrag] forKey:@"touchType"];
////                    }
////                }
//                
//            } else if (touch.tapCount > 0) {
//                [DopamineKit track:@"UIApplication_sendEvent_touchEnded" metaData:@{@"touchType": @"tap",
//                                                                                    @"count": [NSNumber numberWithInteger:touch.tapCount]
//                                                                                    }];
//            }
//            firstTouchHash = false;
//            
//            
//        } else if (touch.phase == UITouchPhaseCancelled) {
//            firstTouchHash = false;
//        }
//        
//    } else if (event.allTouches.count == 2) {
//        
//        UITouch *touch1;
//        UITouch *touch2;
//        if (event.allTouches.allObjects[0].hash == firstTouchHash) {
//            touch1 = event.allTouches.allObjects[0];
//            touch2 = event.allTouches.allObjects[1];
//        } else {
//            touch1 = event.allTouches.allObjects[1];
//            touch2 = event.allTouches.allObjects[0];
//        }
//        
//        if (touch2.view == NULL) {
//            // touch2 in same view as touch1 --> pinch
//            if (touch2.phase == UITouchPhaseBegan) {
//                startTouchPosition2 = [touch2 locationInView:[touch2 view]];
//            } else if (touch1.phase == UITouchPhaseEnded || touch2.phase == UITouchPhaseEnded) {
//                CGPoint currentTouchPosition1 = [touch1 locationInView:[touch1 view]];
//                CGPoint currentTouchPosition2 = [touch2 locationInView:[touch2 view]];
//                
//                CGFloat startFingerDistance = hypot((startTouchPosition1.x-startTouchPosition2.x), (startTouchPosition1.y-startTouchPosition2.y));
//                CGFloat currentFingerDistance = hypot((currentTouchPosition1.x-currentTouchPosition2.x), (currentTouchPosition1.y-currentTouchPosition2.y));
//                CGFloat pinchDifference = currentFingerDistance - startFingerDistance;
//                if (fabs(pinchDifference) > PINCH_MIN) {
//                    NSString *inOrOut = (currentFingerDistance > startFingerDistance) ? @"in" : @"out";
//                    [DopamineKit track:@"UIApplication_sendEvent_touchEnded" metaData:@{@"touchType": @"zoom",
//                                                                                        @"direction": inOrOut
//                                                                                        }];
//                }
//                
//                if (touch2.phase == UITouchPhaseEnded) {
//                    firstTouchHash = touch1.hash;
//                    startTouchTime = [touch1 timestamp];
//                    startTouchPosition1 = [touch1 locationInView:[touch1 view]];
//                } else {
//                    firstTouchHash = touch2.hash;
//                    startTouchTime = [touch2 timestamp];
//                    startTouchPosition1 = [touch2 locationInView:[touch2 view]];
//                }
//            }
//        } else {
//            // Will support complicated multi-touch later
//        }
//    } else {
//        // Will support multi-touch later
//    }
    
    [self swizzled_sendEvent:event];
}

- (BOOL)swizzled_sendAction:(SEL)action to:(id)target from:(id)sender forEvent:(UIEvent *)event {
    NSString *selectorName = NSStringFromSelector(action);
    // Sometimes this method proxies through to its internal method. We want to ignore those calls.
    if (![selectorName isEqualToString:@"_sendAction:withEvent:"]) {
        [DopamineKit track:@"UIApplication" metaData:@{@"tag": @"sendAction",
                                                       @"sender": NSStringFromClass([sender class]),
                                                       @"target": NSStringFromClass([target class]),
                                                       @"selector": selectorName}
         ];
        [VisualizerAPI recordEventWithSender:NSStringFromClass([sender class]) target:NSStringFromClass([target class]) selector:selectorName event:event];
        
    }
    
    return [self swizzled_sendAction:action to:target from:sender forEvent:event];
}

@end
