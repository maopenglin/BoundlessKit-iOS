//
//  SwizzleHelper.h
//  Pods
//
//  Created by Akash Desai on 8/15/17.
//
//

#ifndef SwizzleHelper_h
#define SwizzleHelper_h

@interface SwizzleHelper : NSObject

+ (BOOL) instanceOverridesSelector:(Class) instance :(SEL) selector;
+ (Class) getClassWithProtocolInHierarchy:(Class) searchClass :(Protocol*) protocolToFind;
+ (NSArray*) ClassGetSubclasses: (Class) parentClass;
+ (BOOL) injectSelector:(Class) swizzledClass :(SEL) swizzledSelector :(Class) originalClass :(SEL) orignalSelector;
+ (BOOL) injectToProperClass:(SEL) swizzledSelector :(SEL) orignalSelector :(NSArray*) delegateSubclasses :(Class) swizzledClass :(Class) delegateClass;

@end

#endif /* SwizzleHelper_h */
