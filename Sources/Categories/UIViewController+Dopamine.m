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

@implementation DopamineViewController

+ (void) swizzleSelectors {
    [SwizzleHelper injectSelector:[DopamineViewController class] :@selector(swizzled_viewDidAppear:) :[UIViewController class] :@selector(viewDidAppear:)];
    [SwizzleHelper injectSelector:[DopamineViewController class] :@selector(swizzled_viewDidDisappear:) :[UIViewController class] :@selector(viewDidDisappear:)];
}

- (void) swizzled_viewDidAppear:(BOOL)animated {
    if ([self respondsToSelector:@selector(swizzled_viewDidAppear:)])
        [self swizzled_viewDidAppear:animated];
    
    if ([[DopeConfig shared] trackingApplicationViewsEnabled]) {
        [DopamineKit track:@"UIViewController" metaData:@{@"instanceClass": NSStringFromClass([self class]),
                                                          @"tag": @"didAppear"}];
    }
}

- (void) swizzled_viewDidDisappear:(BOOL)animated {
    if ([self respondsToSelector:@selector(swizzled_viewDidDisappear:)])
        [self swizzled_viewDidDisappear:animated];
    
    if ([[DopeConfig shared] trackingApplicationViewsEnabled]) {
        [DopamineKit track:@"UIViewController" metaData:@{@"instanceClass": NSStringFromClass([self class]),
                                                          @"tag": @"didDisappear"}];
    }
}
@end
