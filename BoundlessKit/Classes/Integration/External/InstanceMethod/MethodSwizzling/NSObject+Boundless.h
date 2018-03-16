//
//  NSObject+Boundless.h
//  BoundlessKit
//
//  Created by Akash Desai on 1/30/18.
//

#ifndef NSObject_Boundless_h
#define NSObject_Boundless_h

@interface BoundlessObject : NSObject

+ (SEL) createNotificationMethodForClass:(Class)targetClass selector:(SEL)targetSelector;

@end

#endif /* NSObject_Boundless_h */
