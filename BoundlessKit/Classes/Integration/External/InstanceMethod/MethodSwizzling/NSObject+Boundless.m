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

+ (SEL) createNotificationMethodForClass:(Class)targetClass selector:(SEL)targetSelector {
    SEL notificationSelector = NSSelectorFromString([NSString stringWithFormat:@"notifyBefore__%@", NSStringFromSelector(targetSelector)]);
    if (class_getInstanceMethod(targetClass, notificationSelector)) {
        return notificationSelector;
    }
    
    Method originalMethod = class_getInstanceMethod(targetClass, targetSelector);
    if (originalMethod == nil) {
        return nil;
    }
    const char* methodTypeEncoding = method_getTypeEncoding(originalMethod);
    NSString* methodTypeEncodingString = [NSString stringWithUTF8String:methodTypeEncoding];
    
    IMP dynamicImp;
    void (^postNotificationBlock)(id target, id sender) = ^void(id target, id sender) {
//        NSLog(@"In dynamic imp with class:%@ and selector:%@ and originalSelector:%@", NSStringFromClass([target class]), NSStringFromSelector(newSelector), NSStringFromSelector(originalSelector));
        [InstanceSelectorNotificationCenter postSelectionWithTargetInstance:target selector:targetSelector senderInstance:sender];
    };
    
    if ([self compareMethodCreationTypeEncodings:methodTypeEncodingString :@selector(templateMethodWithNoParam)]) {
        dynamicImp = [BoundlessObject createImpWithNoParam:notificationSelector :postNotificationBlock];
    } else if ([self compareMethodCreationTypeEncodings:methodTypeEncodingString :@selector(templateMethodWithObjectParam:)]) {
        dynamicImp = [BoundlessObject createImpWithObjectParam:notificationSelector :postNotificationBlock];
    } else if ([self compareMethodCreationTypeEncodings:methodTypeEncodingString :@selector(templateMethodWithBoolParam:)]) {
        dynamicImp = [BoundlessObject createImpWithBoolParam:notificationSelector :postNotificationBlock];
    } else {
        NSLog(@"Unsupported encoding:%@", methodTypeEncodingString);
        return nil;
    }
    
    class_addMethod(targetClass, notificationSelector, dynamicImp, methodTypeEncoding);
    
    Method newMethod = class_getInstanceMethod(targetClass, targetSelector);
    if (newMethod == nil) {
        return nil;
    }
    const char* newMethodTypeEncoding = method_getTypeEncoding(newMethod);
    NSString* newMethodTypeEncodingString = [NSString stringWithUTF8String:newMethodTypeEncoding];
    if (![methodTypeEncodingString isEqualToString:newMethodTypeEncodingString]) {
        return nil;
    }
    
    return notificationSelector;
}

- (void) templateMethodWithNoParam { }
+ (IMP) createImpWithNoParam :(SEL) selector :(void (^)(id,id)) blockBefore {
    IMP dynamicImp = imp_implementationWithBlock(^(id self) {
        if (!self || ![self respondsToSelector:selector]) {return;}
        blockBefore(self, nil);
        ((void (*)(id, SEL))[self methodForSelector:selector])(self, selector);
    });
    
    return dynamicImp;
}

- (void) templateMethodWithObjectParam :(id) param1 { }
+ (IMP) createImpWithObjectParam :(SEL) selector :(void (^)(id,id)) blockBefore {
    IMP dynamicImp = imp_implementationWithBlock(^(id self, id param) {
        if (!self || ![self respondsToSelector:selector]) {return;}
        blockBefore(self, param);
        ((void (*)(id, SEL, id))[self methodForSelector:selector])(self, selector, param);
    });
    
    return dynamicImp;
}

- (void) templateMethodWithBoolParam :(bool) param1 { }
+ (IMP) createImpWithBoolParam :(SEL) selector :(void (^)(id,id)) blockBefore {
    IMP dynamicImp = imp_implementationWithBlock(^(id self, bool param) {
        if (!self || ![self respondsToSelector:selector]) {return;}
        blockBefore(self, nil);
        ((void (*)(id, SEL, bool))[self methodForSelector:selector])(self, selector, param);
    });
    
    return dynamicImp;
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
    
@end
