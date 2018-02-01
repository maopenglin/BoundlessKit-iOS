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

- (void) testImp;

- (IMP) createImp :(NSString*) name;
    
@end

#endif /* NSObject_Dopamine_h */
