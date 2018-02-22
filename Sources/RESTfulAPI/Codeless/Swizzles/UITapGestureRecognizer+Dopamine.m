//
//  UITapGestureRecognizer+Dopamine.m
//  Pods
//
//  Created by Akash Desai on 12/11/17.
//
//

#import <UITapGestureRecognizer+Dopamine.h>

#import <DopamineKit/DopamineKit-swift.h>
#import <SwizzleHelper.h>

#import <objc/runtime.h>

@implementation DopamineTapGestureRecognizer

+ (void) enhanceSelectors: (BOOL) enable {
    @synchronized(self) {
        static BOOL didEnhance = false;
        if (enable ^ didEnhance) {
            didEnhance = !didEnhance;
            
            [SwizzleHelper injectSelector:[DopamineTapGestureRecognizer class] :@selector(enhanced_initWithTarget:action:) :[UITapGestureRecognizer class] :@selector(initWithTarget:action:)];
            [SwizzleHelper injectSelector:[DopamineTapGestureRecognizer class] :@selector(enhanced_addTarget:action:) :[UITapGestureRecognizer class] :@selector(addTarget:action:)];
        }
    }
    
}

- (instancetype) enhanced_initWithTarget:(id)target action:(SEL)action {
    if (target && action) {
        [SelectorReinforcement integrationModeSubmitWithTargetInstance:target action:action];
    }
    
    return [self enhanced_initWithTarget:target action:action];
}

- (void) enhanced_addTarget:(id)target action:(SEL)action {
    if (target && action) {
        [SelectorReinforcement integrationModeSubmitWithTargetInstance:target action:action];
    }
    
    if ([self respondsToSelector:@selector(enhanced_addTarget:action:)])
    [self enhanced_addTarget:target action:action];
}

@end

