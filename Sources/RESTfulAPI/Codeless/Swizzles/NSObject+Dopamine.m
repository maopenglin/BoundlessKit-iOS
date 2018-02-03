//
//  NSObject+Dopamine.m
//  DopamineKit
//
//  Created by Akash Desai on 1/30/18.
//

#import "NSObject+Dopamine.h"

#import <DopamineKit/DopamineKit-Swift.h>

@implementation DopamineObject

- (void) methodToReinforce {
    [SelectorReinforcement attemptReinforcementWithTarget:self action:_cmd];
    [self methodToReinforce];
}

- (void) methodWithSenderToReinforce :(id)sender {
    [SelectorReinforcement attemptReinforcementWithSender: sender target:self action:_cmd];
    [self methodWithSenderToReinforce :sender];
}

+ (IMP) createImp :(SEL) selector {
    IMP dynamicImp = imp_implementationWithBlock(^(id self) {
        if (!self || ![self respondsToSelector:selector]) {return;}
        NSLog(@"In dynamic imp with class:%@ and selector:%@", NSStringFromClass([self class]), NSStringFromSelector(selector));
        
        ((void (*)(id, SEL))[self methodForSelector:selector])(self, selector);
    });
    
    return dynamicImp;
}

+ (IMP) createImpWithObjectParam :(SEL) selector {
    IMP dynamicImp = imp_implementationWithBlock(^(id self, id object) {
        if (!self || ![self respondsToSelector:selector]) {return;}
        NSLog(@"In dynamic imp with class:%@ and selector:%@ and parameter:%@", NSStringFromClass([self class]), NSStringFromSelector(selector), object);
        
        ((void (*)(id, SEL, id))[self methodForSelector:selector])(self, selector, object);
    });
    
    return dynamicImp;
}

+ (IMP) createImpWithIntParam :(SEL) selector {
    IMP dynamicImp = imp_implementationWithBlock(^(id self, int object) {
        if (!self || ![self respondsToSelector:selector]) {return;}
        NSLog(@"In dynamic imp with class:%@ and selector:%@ and parameter:%d", NSStringFromClass([self class]), NSStringFromSelector(selector), object);
        
        ((void (*)(id, SEL, int))[self methodForSelector:selector])(self, selector, object);
    });
    
    return dynamicImp;
}

@end
