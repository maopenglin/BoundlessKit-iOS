//
//  NSObject+Boundless.m
//  BoundlessKit
//
//  Created by Akash Desai on 1/30/18.
//

#import "NSObject+Boundless.h"

#import <BoundlessKit/BoundlessKit-Swift.h>
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

@implementation BoundlessObject

+ (SEL) createTrampolineForClass:(Class)targetClass selector:(SEL)targetSelector withBlock:(SelectorTrampolineBlock) block {
    SEL trampolineSelector = NSSelectorFromString([NSString stringWithFormat:@"notifyBefore__%@", NSStringFromSelector(targetSelector)]);
    if (class_getInstanceMethod(targetClass, trampolineSelector)) {
        return trampolineSelector;
    }
    
    Method originalMethod = class_getInstanceMethod(targetClass, targetSelector);
    if (originalMethod == nil) {
        return nil;
    }
    const char* methodTypeEncoding = method_getTypeEncoding(originalMethod);
    NSString* methodTypeEncodingString = [NSString stringWithUTF8String:methodTypeEncoding];
    
    IMP dynamicImp;
    if ([self compareMethodCreationTypeEncodings:methodTypeEncodingString :[UIApplication self] :@selector(sendAction:to:from:forEvent:)]) {
        dynamicImp = [BoundlessObject createImpForSendAction:targetSelector :trampolineSelector :block];
    } else if ([self compareMethodCreationTypeEncodings:methodTypeEncodingString :[BoundlessObject self] :@selector(templateMethodWithNoParam)]) {
        dynamicImp = [BoundlessObject createImpWithNoParam:targetSelector :trampolineSelector :block];
    } else if ([self compareMethodCreationTypeEncodings:methodTypeEncodingString :[BoundlessObject self] :@selector(templateMethodWithObjectParam:)]) {
        dynamicImp = [BoundlessObject createImpWithObjectParam:targetSelector :trampolineSelector :block];
    } else if ([self compareMethodCreationTypeEncodings:methodTypeEncodingString :[BoundlessObject self] :@selector(templateMethodWithObjectObjectParam::)]) {
        dynamicImp = [BoundlessObject createImpWithObjectObjectParam:targetSelector :trampolineSelector :block];
    } else if ([self compareMethodCreationTypeEncodings:methodTypeEncodingString :[BoundlessObject self] :@selector(templateMethodWithObjectBoolObjectParam:::)]) {
        dynamicImp = [BoundlessObject createImpWithObjectBoolObjectParam:targetSelector :trampolineSelector :block];
    } else if ([self compareMethodCreationTypeEncodings:methodTypeEncodingString :[BoundlessObject self] :@selector(templateMethodWithBoolParam:)]) {
        dynamicImp = [BoundlessObject createImpWithBoolParam:targetSelector :trampolineSelector :block];
    } else {
        NSLog(@"Unsupported encoding:%@ other:%@", methodTypeEncodingString, [NSString stringWithUTF8String: method_getTypeEncoding(class_getInstanceMethod(UIApplication.self, @selector(sendAction:to:from:forEvent:)))]);
        return nil;
    }
    
    class_addMethod(targetClass, trampolineSelector, dynamicImp, methodTypeEncoding);
    
    Method newMethod = class_getInstanceMethod(targetClass, targetSelector);
    if (newMethod == nil) {
        return nil;
    }
    const char* newMethodTypeEncoding = method_getTypeEncoding(newMethod);
    NSString* newMethodTypeEncodingString = [NSString stringWithUTF8String:newMethodTypeEncoding];
    if (![methodTypeEncodingString isEqualToString:newMethodTypeEncodingString]) {
        return nil;
    }
    
    return trampolineSelector;
}

+ (IMP) createImpForSendAction :(SEL) targetSelector :(SEL) selector :(SelectorTrampolineBlock) trampBlock {
    IMP dynamicImp = imp_implementationWithBlock(^(id self, SEL action, id target, id sender, UIEvent* event) {
        trampBlock(target, action, sender);
        if (!self || ![self respondsToSelector:selector]) {return;}
        ((BOOL (*)(id, SEL, SEL, id, id, UIEvent*))[self methodForSelector:selector])(self, selector, action, target, sender, event);
    });
    
    return dynamicImp;
}

- (void) templateMethodWithNoParam { }
+ (IMP) createImpWithNoParam :(SEL) targetSelector :(SEL) selector :(SelectorTrampolineBlock) trampBlock {
    IMP dynamicImp = imp_implementationWithBlock(^(id self) {
        trampBlock(self, targetSelector, nil);
        if (!self || ![self respondsToSelector:selector]) {return;}
        ((void (*)(id, SEL))[self methodForSelector:selector])(self, selector);
    });
    
    return dynamicImp;
}

- (void) templateMethodWithObjectParam :(id) param1 { }
+ (IMP) createImpWithObjectParam :(SEL) targetSelector :(SEL) selector :(SelectorTrampolineBlock) trampBlock {
    IMP dynamicImp = imp_implementationWithBlock(^(id self, id param) {
        trampBlock(self, targetSelector, param);
        if (!self || ![self respondsToSelector:selector]) {return;}
        ((void (*)(id, SEL, id))[self methodForSelector:selector])(self, selector, param);
    });
    
    return dynamicImp;
}

- (void) templateMethodWithObjectObjectParam :(id) param1 :(id) param2 { }
+ (IMP) createImpWithObjectObjectParam :(SEL) targetSelector :(SEL) selector :(SelectorTrampolineBlock) trampBlock {
    IMP dynamicImp = imp_implementationWithBlock(^(id self, id param1, id param2) {
        trampBlock(self, targetSelector, param1);
        if (!self || ![self respondsToSelector:selector]) {return;}
        ((void (*)(id, SEL, id, id))[self methodForSelector:selector])(self, selector, param1, param2);
    });
    
    return dynamicImp;
}

- (void) templateMethodWithObjectBoolObjectParam :(id) param1 :(BOOL) param2 :(id) param3 { }
+ (IMP) createImpWithObjectBoolObjectParam :(SEL) targetSelector :(SEL) selector :(SelectorTrampolineBlock) trampBlock {
    IMP dynamicImp = imp_implementationWithBlock(^(id self, id param1, BOOL param2, id param3) {
        trampBlock(self, targetSelector, nil);
        if (!self || ![self respondsToSelector:selector]) {return;}
        ((void (*)(id, SEL, id, bool, id))[self methodForSelector:selector])(self, selector, param1, param2, param3);
    });
    
    return dynamicImp;
}

- (void) templateMethodWithBoolParam :(bool) param1 { }
+ (IMP) createImpWithBoolParam :(SEL) targetSelector :(SEL) selector :(SelectorTrampolineBlock) trampBlock {
    IMP dynamicImp = imp_implementationWithBlock(^(id self, bool param) {
        trampBlock(self, targetSelector, nil);
        if (!self || ![self respondsToSelector:selector]) {return;}
        ((void (*)(id, SEL, bool))[self methodForSelector:selector])(self, selector, param);
    });
    
    return dynamicImp;
}

+ (BOOL) compareMethodCreationTypeEncodings :(NSString*) candidate :(Class) templateClass :(SEL) templateSelector {
    Method templateMethod = class_getInstanceMethod(templateClass, templateSelector);
    if (templateMethod == nil) {
        return false;
    }
    const char* templateMethodTypeEncoding = method_getTypeEncoding(templateMethod);
    
    NSString* templateMethodTypeEncodingString = [NSString stringWithUTF8String:templateMethodTypeEncoding];
    return [templateMethodTypeEncodingString isEqualToString:candidate];
}
    
@end
