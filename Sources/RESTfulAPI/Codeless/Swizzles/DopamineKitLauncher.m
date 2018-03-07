//
//  DopamineKitLauncher.m
//  Pods
//
//  Created by Akash Desai on 6/16/17.
//
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#import <DopamineKit/DopamineKit-Swift.h>

@implementation UIApplication (DopamineKitLauncher)

+ (void) load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([[[NSProcessInfo processInfo] environment] objectForKey:@"skipLoadLaunch"] == nil) {
            (void)[DopamineKit shared];
        } else {
            NSLog(@"Environment variable:%@", [[[NSProcessInfo processInfo] environment] objectForKey:@"skipLoadLaunch"]);
        }
    });
}

@end

