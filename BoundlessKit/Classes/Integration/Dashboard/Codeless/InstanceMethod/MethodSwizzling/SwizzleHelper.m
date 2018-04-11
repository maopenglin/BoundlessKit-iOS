//
//  SwizzleHelper.m
//  Pods
//
//  Created by Akash Desai on 8/15/17.
//
//

#import <SwizzleHelper.h>

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@implementation SwizzleHelper

+ (BOOL) injectSelector:(Class) swizzledClass :(SEL) swizzledSelector :(Class) originalClass :(SEL) orignalSelector {
//    NSLog(@"Injecting selector %@ for class %@ with %@", NSStringFromSelector(orignalSelector), NSStringFromClass(originalClass), NSStringFromSelector(swizzledSelector));
    Method newMeth = class_getInstanceMethod(swizzledClass, swizzledSelector);
    IMP imp = method_getImplementation(newMeth);
    const char* methodTypeEncoding = method_getTypeEncoding(newMeth);
    
    BOOL existing = class_getInstanceMethod(originalClass, orignalSelector) != NULL;
    
    if (existing) {
        class_addMethod(originalClass, swizzledSelector, imp, methodTypeEncoding);
        newMeth = class_getInstanceMethod(originalClass, swizzledSelector);
        Method orgMeth = class_getInstanceMethod(originalClass, orignalSelector);
        method_exchangeImplementations(orgMeth, newMeth);
    } else {
        class_addMethod(originalClass, orignalSelector, imp, methodTypeEncoding);
    }
    
    return existing;
}

+ (NSArray*) classesConforming: (Protocol*) protocol {
    
    int numClasses = objc_getClassList(NULL, 0);
    Class *classes = (Class *)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
    
    NSMutableArray *result = [NSMutableArray array];
    for (NSInteger i = 0; i < numClasses; i++) {
        Class class = classes[i];
        Class superClass = class_getSuperclass(class);
        if (class_conformsToProtocol(class, protocol) && (superClass == nil || !class_conformsToProtocol(superClass, protocol))) {
            [result addObject:classes[i]];
//            NSLog(@"Found for protocol:%@ class:%@", protocol, class);
        }
    }
    
    free(classes);
    
    return result;
}

+ (NSArray*) classesInheriting: (Class) parentClass {
    
    int numClasses = objc_getClassList(NULL, 0);
    Class *classes = (Class *)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
    
    NSMutableArray *result = [NSMutableArray array];
    for (NSInteger i = 0; i < numClasses; i++) {
        Class superClass = classes[i];
        
        while(superClass && superClass != parentClass) {
            superClass = class_getSuperclass(superClass);
        }
        
        if (superClass) {
            [result addObject:classes[i]];
        }
    }
    
    free(classes);
    
    return result;
}

@end
