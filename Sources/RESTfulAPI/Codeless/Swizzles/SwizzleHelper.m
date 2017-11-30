//
//  DTHelper.m
//  Pods
//
//  Created by Akash Desai on 8/15/17.
//
//

#import <SwizzleHelper.h>

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@implementation SwizzleHelper


+ (BOOL) instanceOverridesSelector:(Class) instance :(SEL) selector {
    return [instance instanceMethodForSelector: selector] != [[instance superclass] instanceMethodForSelector: selector];
}

+ (Class) getClassWithProtocolInHierarchy:(Class) searchClass :(Protocol*) protocolToFind {
    if (!class_conformsToProtocol(searchClass, protocolToFind)) {
        if ([searchClass superclass] == nil)
            return nil;
        Class foundClass = [SwizzleHelper getClassWithProtocolInHierarchy :[searchClass superclass] :protocolToFind];
        if (foundClass)
            return foundClass;
    }
    return searchClass;
}

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
    else
        class_addMethod(originalClass, orignalSelector, imp, methodTypeEncoding);
    
    return existing;
}


+ (BOOL) injectToProperClass:(SEL) swizzledSelector :(SEL) orignalSelector :(NSArray*) delegateSubclasses :(Class) swizzledClass :(Class) delegateClass {
    
    // Inject one of two ways: in subclass or delegate class
    
    for(Class subclass in delegateSubclasses) {
        if ([SwizzleHelper instanceOverridesSelector:subclass :orignalSelector]) {
            return [SwizzleHelper injectSelector:swizzledClass :swizzledSelector :subclass :orignalSelector];
        }
    }
    
    return [SwizzleHelper injectSelector:swizzledClass :swizzledSelector :delegateClass :orignalSelector];
}

+ (NSArray*) ClassGetSubclasses: (Class) parentClass {
    
    int numClasses = objc_getClassList(NULL, 0);
    Class *classes = NULL;
    
    classes = (Class *)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
    
    NSMutableArray *result = [NSMutableArray array];
    for (NSInteger i = 0; i < numClasses; i++) {
        Class superClass = classes[i];
        do {
            superClass = class_getSuperclass(superClass);
        } while(superClass && superClass != parentClass);
        
        if (superClass == nil) continue;
        [result addObject:classes[i]];
    }
    
    free(classes);
    
    return result;
}

@end
