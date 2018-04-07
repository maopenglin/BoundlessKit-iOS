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
    Method originalMethod = class_getInstanceMethod(targetClass, targetSelector);
    if (originalMethod == nil) {
        return nil;
    }
    
    SEL trampolineSelector = NSSelectorFromString([NSString stringWithFormat:@"notifyBefore__%@", NSStringFromSelector(targetSelector)]);
    if (class_getInstanceMethod(targetClass, trampolineSelector) && class_overridesSelector(targetClass, trampolineSelector)) {
        return trampolineSelector;
    }
    const char* methodTypeEncoding = method_getTypeEncoding(originalMethod);
    NSString* methodTypeEncodingString = [NSString stringWithUTF8String:methodTypeEncoding];
    
    BOOL success;
    if (compareMethodCreationTypeEncodings(methodTypeEncodingString, [UIApplication self], @selector(sendAction:to:from:forEvent:))) {
        success = [BoundlessObject addTrampolineForSendAction :targetClass :targetSelector :trampolineSelector :block];
    } else if (compareMethodCreationTypeEncodings(methodTypeEncodingString, [BoundlessObject self], @selector(templateMethodWithNoParam))) {
        success = [BoundlessObject addTrampolineWithNoParam:targetClass :targetSelector :trampolineSelector :block];
    } else if (compareMethodCreationTypeEncodings(methodTypeEncodingString, [BoundlessObject self], @selector(templateMethodWithObjectParam:))) {
        success = [BoundlessObject addTrampolineWithObjectParam :targetClass :targetSelector :trampolineSelector :block];
    } else if (compareMethodCreationTypeEncodings(methodTypeEncodingString, [BoundlessObject self], @selector(templateMethodWithObjectObjectParam::))) {
        success = [BoundlessObject addTrampolineWithObjectObjectParam:targetClass :targetSelector :trampolineSelector :block];
    } else if (compareMethodCreationTypeEncodings(methodTypeEncodingString, [BoundlessObject self], @selector(templateMethodWithObjectBoolObjectParam:::))) {
        success = [BoundlessObject addTrampolineWithObjectBoolObjectParam:targetClass :targetSelector :trampolineSelector :block];
    } else if (compareMethodCreationTypeEncodings(methodTypeEncodingString, [BoundlessObject self], @selector(templateMethodWithBoolParam:))) {
        success = [BoundlessObject addTrampolineWithBoolParam:targetClass :targetSelector :trampolineSelector :block];
    } else {
        NSLog(@"Unsupported encoding:%@ other:%@", methodTypeEncodingString, [NSString stringWithUTF8String: method_getTypeEncoding(class_getInstanceMethod(UIApplication.self, @selector(sendAction:to:from:forEvent:)))]);
        return nil;
    }
    
    return success ? trampolineSelector : nil;
}

+ (BOOL) addTrampolineForSendAction :(Class) targetClass :(SEL) targetSelector :(SEL) trampolineSelector :(SelectorTrampolineBlock) trampolineBlock {
    BOOL success = true;
    
    const char* methodEncoding = method_getTypeEncoding(class_getInstanceMethod(targetClass, targetSelector));
    if (class_getInstanceMethod([targetClass superclass], targetSelector) != NULL && !class_overridesSelector(targetClass, targetSelector)) {
        IMP callSuperImp = imp_implementationWithBlock(^(id self, SEL action, id target, id sender, UIEvent* event) {
            ((BOOL (*)(id, SEL, SEL, id, id, UIEvent*)) [class_getSuperclass(targetClass) instanceMethodForSelector: targetSelector]) (self, trampolineSelector, action, target, sender, event);
        });
        success = success && class_addMethod(targetClass, targetSelector, callSuperImp, methodEncoding);
    }
    
    IMP trampolineImp = imp_implementationWithBlock(^(id self, SEL action, id target, id sender, UIEvent* event) {
        IMP targetImp = [targetClass instanceMethodForSelector: trampolineSelector];
        if (!self || !targetImp) {return;}
        trampolineBlock([target class], action, target, sender);
        ((BOOL(*) (id, SEL, SEL, id, id, UIEvent*)) targetImp) (self, trampolineSelector, action, target, sender, event);
    });
    success = success && class_addMethod(targetClass, trampolineSelector, trampolineImp, methodEncoding);
    
    return success;
}

- (void) templateMethodWithNoParam { }
+ (BOOL) addTrampolineWithNoParam :(Class) targetClass :(SEL) targetSelector :(SEL) trampolineSelector :(SelectorTrampolineBlock) trampolineBlock {
    BOOL success = true;
    
    const char* methodEncoding = method_getTypeEncoding(class_getInstanceMethod(targetClass, targetSelector));
    if (!class_overridesSelector(targetClass, targetSelector)) {
        IMP callSuperImp = imp_implementationWithBlock(^(id self) {
            ((void (*)(id, SEL)) [class_getSuperclass(targetClass) instanceMethodForSelector: targetSelector]) (self, targetSelector);
        });
        success = success && class_addMethod(targetClass, targetSelector, callSuperImp, methodEncoding);
    }
    
    IMP trampolineImp = imp_implementationWithBlock(^(id self) {
        IMP targetImp = [targetClass instanceMethodForSelector: trampolineSelector];
        if (!self || !targetImp) {return;}
        trampolineBlock(targetClass, targetSelector, self, nil);
        ((void(*) (id, SEL)) targetImp) (self, targetSelector);
    });
    success = success && class_addMethod(targetClass, trampolineSelector, trampolineImp, methodEncoding);
    
    return success;
}

- (void) templateMethodWithObjectParam :(id) param { }
+ (BOOL) addTrampolineWithObjectParam :(Class) targetClass :(SEL) targetSelector :(SEL) trampolineSelector :(SelectorTrampolineBlock) trampolineBlock {
    BOOL success = true;
    
    const char* methodEncoding = method_getTypeEncoding(class_getInstanceMethod(targetClass, targetSelector));
    if (!class_overridesSelector(targetClass, targetSelector)) {
        IMP callSuperImp = imp_implementationWithBlock(^(id self, id param) {
            ((void(*) (id, SEL, id)) [class_getSuperclass(targetClass) instanceMethodForSelector: targetSelector]) (self, targetSelector, param);
        });
        success = success && class_addMethod(targetClass, targetSelector, callSuperImp, methodEncoding);
    }
    
    IMP trampolineImp = imp_implementationWithBlock(^(id self, id param) {
        IMP targetImp = [targetClass instanceMethodForSelector: trampolineSelector];
        if (!self || !targetImp) {return;}
        trampolineBlock(targetClass, targetSelector, self, param);
        ((void(*) (id, SEL, id)) targetImp) (self, targetSelector, param);
    });
    success = success && class_addMethod(targetClass, trampolineSelector, trampolineImp, methodEncoding);
    
    return success;
}

- (void) templateMethodWithObjectObjectParam :(id) param1 :(id) param2 { }
+ (BOOL) addTrampolineWithObjectObjectParam :(Class) targetClass :(SEL) targetSelector :(SEL) trampolineSelector :(SelectorTrampolineBlock) trampolineBlock {
    BOOL success = true;
    
    const char* methodEncoding = method_getTypeEncoding(class_getInstanceMethod(targetClass, targetSelector));
    if (!class_overridesSelector(targetClass, targetSelector)) {
        IMP callSuperImp = imp_implementationWithBlock(^(id self, id param1, id param2) {
            ((void(*) (id, SEL, id, id)) [class_getSuperclass(targetClass) instanceMethodForSelector:targetSelector]) (self, trampolineSelector, param1, param2);
        });
        success = success && class_addMethod(targetClass, targetSelector, callSuperImp, methodEncoding);
    }
    
    IMP trampolineImp = imp_implementationWithBlock(^(id self, id param1, id param2) {
        IMP targetImp = [targetClass instanceMethodForSelector: trampolineSelector];
        if (!self || !targetImp) {return;}
        trampolineBlock(targetClass, targetSelector, self, param1);
        ((void(*) (id, SEL, id, id)) targetImp) (self, trampolineSelector, param1, param2);
    });
    success = success && class_addMethod(targetClass, trampolineSelector, trampolineImp, methodEncoding);
    
    return success;
}

- (void) templateMethodWithObjectBoolObjectParam :(id) param1 :(BOOL) param2 :(id) param3 { }
+ (BOOL) addTrampolineWithObjectBoolObjectParam :(Class) targetClass :(SEL) targetSelector :(SEL) trampolineSelector :(SelectorTrampolineBlock) trampolineBlock {
    BOOL success = true;
    
    const char* methodEncoding = method_getTypeEncoding(class_getInstanceMethod(targetClass, targetSelector));
    if (!class_overridesSelector(targetClass, targetSelector)) {
        IMP callSuperImp = imp_implementationWithBlock(^(id self, id param1, BOOL param2, id param3) {
            ((void(*) (id, SEL, id, bool, id)) [class_getSuperclass(targetClass) instanceMethodForSelector:targetSelector]) (self, trampolineSelector, param1, param2, param3);
        });
        success = success && class_addMethod(targetClass, targetSelector, callSuperImp, methodEncoding);
    }
    
    IMP trampolineImp = imp_implementationWithBlock(^(id self, id param1, BOOL param2, id param3) {
        IMP targetImp = [targetClass instanceMethodForSelector: trampolineSelector];
        if (!self || !targetImp) {return;}
        trampolineBlock(targetClass, targetSelector, self, param1);
        ((void(*) (id, SEL, id, bool, id)) targetImp) (self, trampolineSelector, param1, param2, param3);
    });
    success = success && class_addMethod(targetClass, trampolineSelector, trampolineImp, methodEncoding);
    
    return success;
}

- (void) templateMethodWithBoolParam :(bool) param1 { }
+ (BOOL) addTrampolineWithBoolParam :(Class) targetClass :(SEL) targetSelector :(SEL) trampolineSelector :(SelectorTrampolineBlock) trampolineBlock {
    BOOL success = true;
    
    const char* methodEncoding = method_getTypeEncoding(class_getInstanceMethod(targetClass, targetSelector));
    if (!class_overridesSelector(targetClass, targetSelector)) {
//        NSLog(@"Overriding selector <%@> for class <%@>", NSStringFromSelector(targetSelector), NSStringFromClass(targetClass));
        IMP callSuperImp = imp_implementationWithBlock(^(id self, bool param) {
            ((void (*)(id, SEL, bool))[class_getSuperclass(targetClass) instanceMethodForSelector:targetSelector])(self, targetSelector, param);
        });
        success = success && class_addMethod(targetClass, targetSelector, callSuperImp, methodEncoding);
    }
    
    IMP trampolineImp = imp_implementationWithBlock(^(id self, bool param) {
        IMP targetImp = [targetClass instanceMethodForSelector: trampolineSelector];
        if (!self || !targetImp) {return;}
        trampolineBlock(targetClass, targetSelector, self, nil);
        ((void(*) (id, SEL, bool)) targetImp) (self, trampolineSelector, param);
    });
    success = success && class_addMethod(targetClass, trampolineSelector, trampolineImp, methodEncoding);
    
    return success;
}

BOOL compareMethodCreationTypeEncodings(NSString* candidate, Class templateClass, SEL templateSelector) {
    Method templateMethod = class_getInstanceMethod(templateClass, templateSelector);
    if (templateMethod == nil) {
        return false;
    }
    const char* templateMethodTypeEncoding = method_getTypeEncoding(templateMethod);
    
    NSString* templateMethodTypeEncodingString = [NSString stringWithUTF8String:templateMethodTypeEncoding];
    return [templateMethodTypeEncodingString isEqualToString:candidate];
}

BOOL class_overridesSelector(Class aClass, SEL aSelector) {
    Class superClass = class_getSuperclass(aClass);
    return superClass == nil || class_getInstanceMethod(superClass, aSelector) == nil || [aClass instanceMethodForSelector: aSelector] != [superClass instanceMethodForSelector: aSelector];
}
    
@end
