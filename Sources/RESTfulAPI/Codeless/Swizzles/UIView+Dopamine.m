//
//  UIView+Dopamine.m
//  Pods
//
//  Created by Akash Desai on 12/6/17.
//
//

#import <UIView+Dopamine.h>

#import <DopamineKit/DopamineKit-swift.h>
#import <SwizzleHelper.h>

#import <objc/runtime.h>

@implementation DopamineView

+ (void) swizzleSelectors {
//    [SwizzleHelper injectSelector:[DopamineView class] :@selector(swizzled_willMoveToWindow:) :[UIView class] :@selector(willMoveToWindow:)];
    [SwizzleHelper injectSelector:[DopamineView class] :@selector(swizzled_willMoveToSuperview:) :[UIView class] :@selector(willMoveToSuperview:)];
}

//- (void) swizzled_willMoveToWindow:(UIWindow *)newWindow {
//    if ([self respondsToSelector:@selector(swizzled_willMoveToWindow:)])
//        [self swizzled_willMoveToWindow:newWindow];
//
//    NSLog(@"View %@ will move to %@", NSStringFromClass([self class]), newWindow == nil ? @"nil" : @"window");
//
////    if ([[DopamineConfiguration current] applicationViews] || [[[DopamineConfiguration current] customViews] objectForKey:NSStringFromClass([self class])]) {
////        [DopamineKit track:@"ApplicationView" metaData:@{@"tag": @"didAppear",
////                                                          @"classname": NSStringFromClass([self class]),
////                                                          @"time": [DopeTimer trackStartTimeFor:[self description]]
////                                                          }];
////    }
//}

- (void) swizzled_willMoveToSuperview:(UIView *)newSuperview {
    if ([self respondsToSelector:@selector(swizzled_willMoveToSuperview:)])
        [self swizzled_willMoveToSuperview: newSuperview];
    
    if (newSuperview != NULL) {
        NSLog(@"View %@ moved to superview %@", NSStringFromClass([self class]), NSStringFromClass([newSuperview class]));
    }
    
}

@end
