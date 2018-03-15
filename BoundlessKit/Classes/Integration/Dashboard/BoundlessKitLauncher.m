//
//  BoundlessKitLauncher.m
//  Pods
//
//  Created by Akash Desai on 6/16/17.
//
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#import <BoundlessKit/BoundlessKit-Swift.h>

@implementation UIApplication (BoundlessKitLauncher)

+ (void) load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        (void)[BoundlessKitLauncherObjc launch];
    });
}

@end

