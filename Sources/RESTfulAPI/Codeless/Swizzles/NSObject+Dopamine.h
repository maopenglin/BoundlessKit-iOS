//
//  NSObject+Dopamine.h
//  DopamineKit
//
//  Created by Akash Desai on 1/30/18.
//

#ifndef NSObject_Dopamine_h
#define NSObject_Dopamine_h

@interface DopamineObject : NSObject
+ (SEL) createReinforcedMethodFor :(Class) targetClass :(SEL) originalSelector :(SEL) newSelector;
@end

#endif /* NSObject_Dopamine_h */
