//
//  NSObject+Boundless.h
//  BoundlessKit
//
//  Created by Akash Desai on 1/30/18.
//

#ifndef NSObject_Boundless_h
#define NSObject_Boundless_h

@interface BoundlessObject : NSObject

+ (BOOL) templateAvailableFor :(Class) classType :(SEL) selector;
+ (SEL) createNotificationMethodFor :(Class) targetClass :(SEL) originalSelector :(SEL) newSelector;

@end

#endif /* NSObject_Boundless_h */
