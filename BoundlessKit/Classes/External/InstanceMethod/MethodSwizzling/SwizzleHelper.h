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

+ (BOOL) injectSelector:(Class) swizzledClass :(SEL) swizzledSelector :(Class) originalClass :(SEL) orignalSelector;

@end

#endif /* SwizzleHelper_h */
