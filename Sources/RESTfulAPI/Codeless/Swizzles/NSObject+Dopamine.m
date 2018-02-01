//
//  NSObject+Dopamine.m
//  DopamineKit
//
//  Created by Akash Desai on 1/30/18.
//

#import "NSObject+Dopamine.h"

#import <DopamineKit/DopamineKit-Swift.h>

@implementation DopamineObject

- (void) methodToReinforce {
    [SelectorReinforcement attemptReinforcementWithTarget:self action:_cmd];
    [self methodToReinforce];
}

- (void) methodWithSenderToReinforce :(id)sender {
    [SelectorReinforcement attemptReinforcementWithSender: sender target:self action:_cmd];
    [self methodWithSenderToReinforce :sender];
}

- (void) testImp {
    static NSString* myName = @"";
    myName = NSStringFromSelector(_cmd);
    NSLog(@"My name:%@ - %@", myName, NSStringFromSelector(@selector(testImp)));
    
    [self testImp];
}

- (IMP) createImp :(NSString*) name {
    IMP dynamicImp = imp_implementationWithBlock(^(id self) {
        NSLog(@"In dynamic imp with name:%@", name);
        [self performSelector:NSSelectorFromString(name)];
    });
    
    return dynamicImp;
}

@end
