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

- (void) dashboardIntegration_viewDidAppear:(BOOL)animated {
    if ([self respondsToSelector:@selector(dashboardIntegration_viewDidAppear:)])
        [self dashboardIntegration_viewDidAppear:animated];
    // TO-DO: test if else call super.viewDidAppear
    
    if (self) {
        [DopamineSelector attemptIntegrationWithSenderInstance: nil targetInstance:self action:@selector(viewDidAppear:)];
    }
}

@end
