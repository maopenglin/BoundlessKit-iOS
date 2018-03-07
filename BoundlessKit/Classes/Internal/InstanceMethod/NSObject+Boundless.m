//
//  NSObject+Boundless.m
//  BoundlessKit
//
//  Created by Akash Desai on 1/30/18.
//

#import "NSObject+Boundless.h"
#import <BoundlessKit/BoundlessKit-Swift.h>
#import <SwizzleHelper.h>

@implementation BoundlessObject

+ (SEL) createReinforcedMethodFor :(Class) targetClass :(SEL) originalSelector :(SEL) newSelector {
    if (class_getInstanceMethod(targetClass, newSelector)) {
        return newSelector;
    }
    
    Method originalMethod = class_getInstanceMethod(targetClass, originalSelector);
    if (originalMethod == nil) {
        return nil;
    }
    const char* methodTypeEncoding = method_getTypeEncoding(originalMethod);
    NSString* methodTypeEncodingString = [NSString stringWithUTF8String:methodTypeEncoding];
    
    IMP dynamicImp;
    void (^reinforceBlock)(id target, id sender) = ^void(id target, id sender) {
//        NSLog(@"In dynamic imp with class:%@ and selector:%@ and originalSelector:%@", NSStringFromClass([target class]), NSStringFromSelector(newSelector), NSStringFromSelector(originalSelector));
        [InstanceMethodNotification postWithTargetInstance:target selector:originalSelector parameter:sender];
    };
    
    if ([self compareMethodCreationTypeEncodings:methodTypeEncodingString :@selector(templateMethodWithNoParam)]) {
        dynamicImp = [BoundlessObject createImpWithNoParam:newSelector :reinforceBlock];
    } else if ([self compareMethodCreationTypeEncodings:methodTypeEncodingString :@selector(templateMethodWithObjectParam:)]) {
        dynamicImp = [BoundlessObject createImpWithObjectParam:newSelector :reinforceBlock];
    } else if ([self compareMethodCreationTypeEncodings:methodTypeEncodingString :@selector(templateMethodWithBoolParam:)]) {
        dynamicImp = [BoundlessObject createImpWithBoolParam:newSelector :reinforceBlock];
    } else {
        NSLog(@"Unsupported encoding:%@", methodTypeEncodingString);
        return nil;
    }
    
    class_addMethod(targetClass, newSelector, dynamicImp, methodTypeEncoding);
    
    Method newMethod = class_getInstanceMethod(targetClass, originalSelector);
    if (newMethod == nil) {
        return nil;
    }
    const char* newMethodTypeEncoding = method_getTypeEncoding(newMethod);
    NSString* newMethodTypeEncodingString = [NSString stringWithUTF8String:newMethodTypeEncoding];
    if (![methodTypeEncodingString isEqualToString:newMethodTypeEncodingString]) {
        return nil;
    }
    
    return newSelector;
}

+ (BOOL) compareMethodCreationTypeEncodings :(NSString*) candidate :(SEL) templateSelector {
    Method templateMethod = class_getInstanceMethod([BoundlessObject self], templateSelector);
    if (templateMethod == nil) {
        return false;
    }
    const char* templateMethodTypeEncoding = method_getTypeEncoding(templateMethod);
    
    NSString* templateMethodTypeEncodingString = [NSString stringWithUTF8String:templateMethodTypeEncoding];
    return [templateMethodTypeEncodingString isEqualToString:candidate];
}

+ (BOOL) templateAvailableFor :(Class) classType :(SEL) selector {
    Method method = class_getInstanceMethod(classType, selector);
    if (method == nil) {
        return false;
    }
    const char* methodTypeEncoding = method_getTypeEncoding(method);
    NSString* methodTypeEncodingString = [NSString stringWithUTF8String:methodTypeEncoding];
    
    return
    [methodTypeEncodingString isEqualToString:[NSString stringWithUTF8String:method_getTypeEncoding(class_getInstanceMethod([BoundlessObject self], @selector(templateMethodWithNoParam)))]] ||
    [methodTypeEncodingString isEqualToString:[NSString stringWithUTF8String:method_getTypeEncoding(class_getInstanceMethod([BoundlessObject self], @selector(templateMethodWithObjectParam:)))]] ||
    [methodTypeEncodingString isEqualToString:[NSString stringWithUTF8String:method_getTypeEncoding(class_getInstanceMethod([BoundlessObject self], @selector(templateMethodWithBoolParam:)))]];
}

- (void) templateMethodWithNoParam { }
+ (IMP) createImpWithNoParam :(SEL) selector :(void (^)(id,id)) reinforceBlock {
    IMP dynamicImp = imp_implementationWithBlock(^(id self) {
        if (!self || ![self respondsToSelector:selector]) {return;}
        reinforceBlock(self, nil);
        ((void (*)(id, SEL))[self methodForSelector:selector])(self, selector);
    });
    
    return dynamicImp;
}

- (void) templateMethodWithObjectParam :(id) param1 { }
+ (IMP) createImpWithObjectParam :(SEL) selector :(void (^)(id,id)) reinforceBlock {
    IMP dynamicImp = imp_implementationWithBlock(^(id self, id param) {
        if (!self || ![self respondsToSelector:selector]) {return;}
        reinforceBlock(self, param);
        ((void (*)(id, SEL, id))[self methodForSelector:selector])(self, selector, param);
    });
    
    return dynamicImp;
}

- (void) templateMethodWithBoolParam :(bool) param1 { }
+ (IMP) createImpWithBoolParam :(SEL) selector :(void (^)(id,id)) reinforceBlock {
    IMP dynamicImp = imp_implementationWithBlock(^(id self, bool param) {
        if (!self || ![self respondsToSelector:selector]) {return;}
        reinforceBlock(self, nil);
        ((void (*)(id, SEL, bool))[self methodForSelector:selector])(self, selector, param);
    });
    
    return dynamicImp;
}

@end
