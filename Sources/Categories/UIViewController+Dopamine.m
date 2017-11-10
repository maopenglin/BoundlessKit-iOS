//
//  UIViewController+Dopamine.m
//  Pods
//
//  Created by Akash Desai on 8/16/17.
//
//

#import <UIViewController+Dopamine.h>

#import <DopamineKit/DopamineKit-swift.h>
#import <SwizzleHelper.h>

#import <objc/runtime.h>

@implementation DopamineViewController

+ (void) swizzleSelectors {
    [SwizzleHelper injectSelector:[DopamineViewController class] :@selector(swizzled_viewDidAppear:) :[UIViewController class] :@selector(viewDidAppear:)];
    [SwizzleHelper injectSelector:[DopamineViewController class] :@selector(swizzled_viewDidDisappear:) :[UIViewController class] :@selector(viewDidDisappear:)];
}

- (void) swizzled_viewDidAppear:(BOOL)animated {
    if ([self respondsToSelector:@selector(swizzled_viewDidAppear:)])
        [self swizzled_viewDidAppear:animated];
    if ([[DopeConfig shared] applicationViews] || [[[DopeConfig shared] customViews] objectForKey:NSStringFromClass([self class])]) {
        [DopamineKit track:@"ApplicationView" metaData:@{@"tag": @"didAppear",
                                                          @"classname": NSStringFromClass([self class]),
                                                          @"time": [DopeTracking trackStartTimeFor:[self description]]
                                                          }];
    }
}

- (void) swizzled_viewDidDisappear:(BOOL)animated {
    if ([self respondsToSelector:@selector(swizzled_viewDidDisappear:)])
        [self swizzled_viewDidDisappear:animated];
    
    if ([[DopeConfig shared] applicationViews]) {
        [DopamineKit track:@"ApplicationView" metaData:@{@"tag": @"didDisappear",
                                                          @"classname": NSStringFromClass([self class]),
                                                          @"time": [DopeTracking timeTrackedFor:[self description]]
                                                              }];
    }
}
@end
