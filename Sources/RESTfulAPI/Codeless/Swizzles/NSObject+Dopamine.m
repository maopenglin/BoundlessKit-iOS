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
    [SelectorReinforcement rForTarget:self action:_cmd];
    [self methodToReinforce];
}

- (void) methodWithSenderToReinforce :(id)sender {
    [SelectorReinforcement rForTarget:self action:_cmd];
    [self methodWithSenderToReinforce :sender];
}

@end
