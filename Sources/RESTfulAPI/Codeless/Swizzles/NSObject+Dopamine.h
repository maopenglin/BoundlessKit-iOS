//
//  NSObject+Dopamine.h
//  DopamineKit
//
//  Created by Akash Desai on 1/30/18.
//

#ifndef NSObject_Dopamine_h
#define NSObject_Dopamine_h

@interface DopamineObject : NSObject

- (void) methodToReinforce;
- (void) methodWithSenderToReinforce :(id)sender;

+ (IMP) createImp :(SEL) selector;
+ (IMP) createImpWithObjectParam :(SEL) selector;
+ (IMP) createImpWithIntParam :(SEL) selector;

@end

#endif /* NSObject_Dopamine_h */
