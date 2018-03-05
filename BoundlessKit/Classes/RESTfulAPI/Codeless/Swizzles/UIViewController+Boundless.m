//
//  UIViewController+Boundless.m
//  Pods
//
//  Created by Akash Desai on 8/16/17.
//
//

#import <UIViewController+Boundless.h>

#import <BoundlessKit/BoundlessKit-Swift.h>
#import <SwizzleHelper.h>

#import <objc/runtime.h>

@implementation BoundlessViewController

+ (void) swizzleSelectors {
    [SwizzleHelper injectSelector:[BoundlessViewController class] :@selector(swizzled_viewDidAppear:) :[UIViewController class] :@selector(viewDidAppear:)];
    [SwizzleHelper injectSelector:[BoundlessViewController class] :@selector(swizzled_viewDidDisappear:) :[UIViewController class] :@selector(viewDidDisappear:)];
}

- (void) swizzled_viewDidAppear:(BOOL)animated {
    if ([self respondsToSelector:@selector(swizzled_viewDidAppear:)])
        [self swizzled_viewDidAppear:animated];
    
    [CodelessAPI submitViewControllerDidAppearWithVc: self target:NSStringFromClass([self class]) action:NSStringFromSelector(@selector(viewDidAppear:))];
    
    if ([[BoundlessConfiguration current] applicationViews] || [[[BoundlessConfiguration current] customViews] objectForKey:NSStringFromClass([self class])]) {
        [BoundlessKit track:@"ApplicationView" metaData:@{@"tag": @"didAppear",
                                                          @"classname": NSStringFromClass([self class]),
                                                          @"time": [BoundlessTimer trackStartTimeFor:[self description]]
                                                          }];
    }
}

- (void) swizzled_viewDidDisappear:(BOOL)animated {
    if ([self respondsToSelector:@selector(swizzled_viewDidDisappear:)])
        [self swizzled_viewDidDisappear:animated];
    
    [CodelessAPI submitViewControllerDidDisappearWithVc: self target:NSStringFromClass([self class]) action:NSStringFromSelector(@selector(viewDidDisappear:))];
    
    if ([[BoundlessConfiguration current] applicationViews]) {
        [BoundlessKit track:@"ApplicationView" metaData:@{@"tag": @"didDisappear",
                                                          @"classname": NSStringFromClass([self class]),
                                                          @"time": [BoundlessTimer timeTrackedFor:[self description]]
                                                              }];
    }
}
@end
