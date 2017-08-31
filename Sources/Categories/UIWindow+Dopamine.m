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


+ (void) swizzleSelectors {
    [SwizzleHelper injectSelector:[DopamineWindow class] :@selector(swizzled_sendEvent:) :[UIWindow class] :@selector(sendEvent:)];
}

static NSUInteger firstTouchHash;
static uint64_t startTouchTime;
static CGPoint startTouchPosition1;
static CGPoint startTouchPosition2;
static CGFloat SWIPE_DRAG_MIN = 80;
static CGFloat PINCH_MIN = 20;

-(void) swizzled_sendEvent: (UIEvent *) event {
    
    if (event.allTouches.count == 1) {
        UITouch *touch = event.allTouches.anyObject;
        
        if (touch.phase == UITouchPhaseBegan) {
            // could be pinch or swipe or drag or tap or hold
            firstTouchHash = touch.hash;
            
            startTouchTime = [touch timestamp];
            startTouchPosition1 = [touch locationInView:self];
        } else if (touch.phase == UITouchPhaseEnded && touch.hash == firstTouchHash) {
            // swipe or drag or tap or hold
            
            CGPoint currentTouchPosition = [touch locationInView:self];
            double xDistance = fabs(startTouchPosition1.x - currentTouchPosition.x);
            double yDistance = fabs(startTouchPosition1.y - currentTouchPosition.y);
            
            if (xDistance >= SWIPE_DRAG_MIN || yDistance >= SWIPE_DRAG_MIN) {
                
                NSString* swipeOrDrag = (touch.timestamp - startTouchTime < 1.0) ? @"Swipe" : @"Drag";
                if (xDistance > yDistance) {
                    if (currentTouchPosition.x > startTouchPosition1.x) {
//                        NSLog(@"%@ right", swipeOrDrag);
                        
                    } else {
                        NSLog(@"%@ left", swipeOrDrag);
                    }
                } else {
                    if (currentTouchPosition.y > startTouchPosition1.y) {
                        NSLog(@"%@ down", swipeOrDrag);
                    } else {
                        NSLog(@"%@ up", swipeOrDrag);
                    }
                }
                
            } else if (touch.tapCount > 0) {
                NSLog(@"tapCount:(%lu)", (unsigned long)touch.tapCount);
            }
            firstTouchHash = false;
        } else if (touch.phase == UITouchPhaseCancelled) {
            firstTouchHash = false;
        }
        
    } else if (event.allTouches.count == 2) {
        
        UITouch *touch1;
        UITouch *touch2;
        if (event.allTouches.allObjects[0].hash == firstTouchHash) {
            touch1 = event.allTouches.allObjects[0];
            touch2 = event.allTouches.allObjects[1];
        } else {
            touch1 = event.allTouches.allObjects[1];
            touch2 = event.allTouches.allObjects[0];
        }
        
        if (touch2.view == NULL) {
            // touch2 in same view as touch1 --> pinch
            if (touch2.phase == UITouchPhaseBegan) {
                startTouchPosition2 = [touch2 locationInView:self];
            } else if (touch1.phase == UITouchPhaseEnded || touch2.phase == UITouchPhaseEnded) {
                CGPoint currentTouchPosition1 = [touch1 locationInView:self];
                CGPoint currentTouchPosition2 = [touch2 locationInView:self];
                
                CGFloat startFingerDistance = hypot((startTouchPosition1.x-startTouchPosition2.x), (startTouchPosition1.y-startTouchPosition2.y));
                CGFloat currentFingerDistance = hypot((currentTouchPosition1.x-currentTouchPosition2.x), (currentTouchPosition1.y-currentTouchPosition2.y));
                CGFloat pinchDifference = currentFingerDistance - startFingerDistance;
                if (fabs(pinchDifference) > PINCH_MIN) {
                    if (currentFingerDistance > startFingerDistance) {
                        NSLog(@"Zoom in");
                    } else {
                        NSLog(@"Zoom out");
                    }
                }
                
                if (touch2.phase == UITouchPhaseEnded) {
                    firstTouchHash = touch1.hash;
                    startTouchTime = [touch1 timestamp];
                    startTouchPosition1 = [touch1 locationInView:self];
                } else {
                    firstTouchHash = touch2.hash;
                    startTouchTime = [touch2 timestamp];
                    startTouchPosition1 = [touch2 locationInView:self];
                }
            }
        } else {
            // Will support complicated multi-touch later
        }
    } else {
        // Will support multi-touch later
    }
    
    [self swizzled_sendEvent:event];
}

@end
