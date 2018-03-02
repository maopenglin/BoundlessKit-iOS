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

+ (void) enhanceSelectors: (BOOL) enable {
    @synchronized(self) {
        static BOOL didEnhance = false;
        if (enable ^ didEnhance) {
            didEnhance = !didEnhance;
            [SwizzleHelper injectSelector:[DopamineViewController class] :@selector(enhanced_viewDidAppear:) :[UIViewController class] :@selector(viewDidAppear:)];
            [SwizzleHelper injectSelector:[DopamineViewController class] :@selector(enhanced_viewDidDisappear:) :[UIViewController class] :@selector(viewDidDisappear:)];
        }
    }
}

- (void) enhanced_viewDidAppear:(BOOL)animated {
    if ([self respondsToSelector:@selector(enhanced_viewDidAppear:)])
        [self enhanced_viewDidAppear:animated];
    
    if (self) {
        [SelectorReinforcement recordActionForTargetInstance:self action:@selector(viewDidAppear:)];
    }
}

- (void) enhanced_viewDidDisappear:(BOOL)animated {
    if ([self respondsToSelector:@selector(enhanced_viewDidDisappear:)])
        [self enhanced_viewDidDisappear:animated];
    
    if (self) {
        [SelectorReinforcement recordActionForTargetInstance:self action:@selector(viewDidDisappear:)];
    }
}

- (void) reinforced_viewDidAppear:(BOOL)animated {
    if ([self respondsToSelector:@selector(reinforced_viewDidAppear:)])
        [self reinforced_viewDidAppear:animated];
    // TO-DO: test if else call super.viewDidAppear
    
    if (self) {
        [SelectorReinforcement attemptReinforcementWithSenderInstance: nil targetInstance:self action:@selector(viewDidAppear:)];
    }
}
@end
