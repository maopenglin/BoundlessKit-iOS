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
#import <SwizzleHelper.h>
#import <UIApplication+Boundless.h>

@implementation UIApplication (BoundlessKitLauncher)

+ (void) load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
//        [SwizzleHelper injectSelector:[BoundlessApp self] :@selector(notifyMessages__sendAction:to:from:forEvent:) :[UIApplication self] :@selector(sendAction:to:from:forEvent:)];
        (void)[BoundlessKitLauncherObjc launch];
    });
}

@end

