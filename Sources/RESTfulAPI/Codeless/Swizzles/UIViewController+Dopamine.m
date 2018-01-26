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
    
    [CodelessAPI submitViewControllerDidAppearWithVc: self target:NSStringFromClass([self class]) action:NSStringFromSelector(@selector(viewDidAppear:))];
    
    if ([[DopamineConfiguration current] applicationViews] || [[[DopamineConfiguration current] customViews] objectForKey:NSStringFromClass([self class])]) {
        [DopamineKit track:@"ApplicationView" metaData:@{@"tag": @"didAppear",
                                                          @"classname": NSStringFromClass([self class]),
                                                          @"time": [DopeTimer trackStartTimeFor:[self description]]
                                                          }];
    }
}

- (void) swizzled_viewDidDisappear:(BOOL)animated {
    if ([self respondsToSelector:@selector(swizzled_viewDidDisappear:)])
        [self swizzled_viewDidDisappear:animated];
    
    [CodelessAPI submitViewControllerDidDisappearWithVc: self target:NSStringFromClass([self class]) action:NSStringFromSelector(@selector(viewDidDisappear:))];
    
    if ([[DopamineConfiguration current] applicationViews] || [[[DopamineConfiguration current] customViews] objectForKey:NSStringFromClass([self class])]) {
        [DopamineKit track:@"ApplicationView" metaData:@{@"tag": @"didDisappear",
                                                          @"classname": NSStringFromClass([self class]),
                                                          @"time": [DopeTimer timeTrackedFor:[self description]]
                                                              }];
    }
}
@end
