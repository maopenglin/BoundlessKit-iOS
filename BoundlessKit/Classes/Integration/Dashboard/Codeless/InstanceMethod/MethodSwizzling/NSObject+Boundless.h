//
//  NSObject+Boundless.h
//  BoundlessKit
//
//  Created by Akash Desai on 1/30/18.
//

#ifndef NSObject_Boundless_h
#define NSObject_Boundless_h

@interface BoundlessObject : NSObject
typedef void (^ SelectorTrampolineBlock)(Class targetClass,  SEL targetSelector, id target,id sender);
+ (SEL) createTrampolineForClass:(Class)targetClass selector:(SEL)targetSelector withBlock:(SelectorTrampolineBlock) block;

@end

#endif /* NSObject_Boundless_h */
