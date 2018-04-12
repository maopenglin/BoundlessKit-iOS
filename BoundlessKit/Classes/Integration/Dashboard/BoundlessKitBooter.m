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
//        [[NSNotificationCenter defaultCenter] addObserver:[BoundlessKitBooterObjc standard] selector:@selector(appDidLaunch:) name:UIApplicationNotification object:nil];
        // ^not swizzling fast enough for reinforcing first view controller
        [[BoundlessKitBooterObjc standard] appDidLaunch: [[NSNotification alloc] initWithName:@"test" object:nil userInfo:nil]];
    });
}

@end

