//
//  DTMethodEnhancement.m
//  Pods
//
//  Created by Akash Desai on 6/16/17.
//
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#import <DopamineKit/DopamineKit-Swift.h>

@implementation UIApplication (DTMethodEnhancement)

+ (void) load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[DopamineChanges shared] wake];
    });
}

@end

