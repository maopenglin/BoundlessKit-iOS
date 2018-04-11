//
//  BoundlessKitLauncher.m
//  Pods
//
//  Created by Akash Desai on 6/16/17.
//
//

#import <BoundlessKit/BoundlessKit-Swift.h>

@implementation UIApplication (BoundlessKitLauncher)

+ (void) load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[NSNotificationCenter defaultCenter] addObserver:[BoundlessKitLauncherObjc shared] selector:@selector(appDidLaunch:) name:UIApplicationDidFinishLaunchingNotification object:nil];
    });
}

@end

