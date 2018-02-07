//
//  NSObject+Dopamine.m
//  DopamineKit
//
//  Created by Akash Desai on 1/30/18.
//

#import "NSObject+Dopamine.h"

#import <DopamineKit/DopamineKit-Swift.h>
#import <SwizzleHelper.h>

@implementation DopamineObject

+ (SEL) createReinforcedMethodFor :(Class) targetClass :(SEL) originalSelector :(SEL) newSelector {
    Method originalMethod = class_getInstanceMethod(targetClass, originalSelector);
    if (originalMethod == nil) {
        return nil;
    }
    if (class_getInstanceMethod(targetClass, newSelector)) {
        return newSelector;
    }
    
    const char* methodTypeEncoding = method_getTypeEncoding(originalMethod);
    NSString* methodTypeEncodingString = @(methodTypeEncoding);
    
    IMP dynamicImp;
    if ([methodTypeEncodingString isEqualToString:@"v@:"]) {
        dynamicImp = [DopamineObject createImpWithNoParam:newSelector :originalSelector];
    } else if ([methodTypeEncodingString isEqualToString:@"v@:@"]) {
        dynamicImp = [DopamineObject createImpWithObjectParam:newSelector :originalSelector];
    } else if ([methodTypeEncodingString isEqualToString:@"v@:i"]) {
        dynamicImp = [DopamineObject createImpWithIntParam:newSelector :originalSelector];
    } else {
        NSLog(@"Unsupported encoding:%@", methodTypeEncodingString);
        return nil;
    }
    
    class_addMethod(targetClass, newSelector, dynamicImp, methodTypeEncoding);
    
    return newSelector;
}

+ (IMP) createImpWithNoParam :(SEL) selector :(SEL) originalSelector {
    IMP dynamicImp = imp_implementationWithBlock(^(id self) {
        if (!self || ![self respondsToSelector:selector]) {return;}
        NSLog(@"In dynamic imp with class:%@ and selector:%@ and originalSelector:%@", NSStringFromClass([self class]), NSStringFromSelector(selector), NSStringFromSelector(originalSelector));
        
        [SelectorReinforcement attemptReinforcementWithTarget:self action:originalSelector];
        ((void (*)(id, SEL))[self methodForSelector:selector])(self, selector);
    });
    
    return dynamicImp;
}

+ (IMP) createImpWithObjectParam :(SEL) selector :(SEL) originalSelector {
    IMP dynamicImp = imp_implementationWithBlock(^(id self, id object) {
        if (!self || ![self respondsToSelector:selector]) {return;}
        NSLog(@"In dynamic imp with class:%@ and selector:%@ and originalSelector:%@ and parameter:%@", NSStringFromClass([self class]), NSStringFromSelector(selector), NSStringFromSelector(originalSelector), object);
        [SelectorReinforcement attemptReinforcementWithTarget:self action:originalSelector];
        ((void (*)(id, SEL, id))[self methodForSelector:selector])(self, selector, object);
    });
    
    return dynamicImp;
}

+ (IMP) createImpWithIntParam :(SEL) selector :(SEL) originalSelector {
    IMP dynamicImp = imp_implementationWithBlock(^(id self, int object) {
        if (!self || ![self respondsToSelector:selector]) {return;}
        NSLog(@"In dynamic imp with class:%@ and selector:%@ and originalSelector:%@ and parameter:%d", NSStringFromClass([self class]), NSStringFromSelector(selector), NSStringFromSelector(originalSelector), object);
        [SelectorReinforcement attemptReinforcementWithTarget:self action:originalSelector];
        
        ((void (*)(id, SEL, int))[self methodForSelector:selector])(self, selector, object);
    });
    
    return dynamicImp;
}

@end
