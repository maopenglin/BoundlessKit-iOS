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
    Method newMeth = class_getInstanceMethod(swizzledClass, swizzledSelector);
    IMP imp = method_getImplementation(newMeth);
    const char* methodTypeEncoding = method_getTypeEncoding(newMeth);
    
    BOOL existing = class_getInstanceMethod(originalClass, orignalSelector) != NULL;
    
    if (existing) {
        class_addMethod(originalClass, swizzledSelector, imp, methodTypeEncoding);
        newMeth = class_getInstanceMethod(originalClass, swizzledSelector);
        Method orgMeth = class_getInstanceMethod(originalClass, orignalSelector);
        method_exchangeImplementations(orgMeth, newMeth);
    }
    else {
        class_addMethod(originalClass, orignalSelector, imp, methodTypeEncoding);
    }
    
    return existing;
}

@end
