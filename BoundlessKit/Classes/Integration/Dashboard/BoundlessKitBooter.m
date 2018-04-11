//
//  BoundlessKitBooter.m
//  Pods
//
//  Created by Akash Desai on 6/16/17.
//
//

#import <BoundlessKit/BoundlessKit-Swift.h>

@implementation UIApplication (BoundlessKitBooter)

+ (void) load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[NSNotificationCenter defaultCenter] addObserver:[BoundlessKitBooterObjc shared] selector:@selector(appDidLaunch:) name:UIApplicationDidFinishLaunchingNotification object:nil];
    });
}

@end

