////
////  NSObject+Dopamine.m
////  Pods
////
////  Created by Akash Desai on 12/11/17.
////
////
//
//#import <NSObject+Dopamine.h>
//
//#import <DopamineKit/DopamineKit-swift.h>
//#import <SwizzleHelper.h>
//
//#import <objc/runtime.h>
//
//@implementation DopamineObject
//
//
//// to-do: check if class inherits from nsobject
//+ (void) swizzleSelectors {
////    [SwizzleHelper injectSelector:[DopamineGestureRecognizer class] :@selector(swizzled_initWithTarget:action:) :[DopamineGestureRecognizer class] :@selector(initWithTarget:action:)];
////    [SwizzleHelper injectSelector:[DopamineViewController class] :@selector(swizzled_viewDidDisappear:) :[UIViewController class] :@selector(viewDidDisappear:)];
////    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
////        NSLog(@"starting");
//        [SwizzleHelper injectSelector:NSClassFromString(@"Space.ContainerViewController") :NSSelectorFromString(@"presentChickletListViewController") :[DopamineObject class] :@selector(performReinforcement)];
//        NSLog(@"yee1");
////    });
//}
//
//- (void) performReinforcement {
//    [self performReinforcement];
//    NSLog(@"yee");
//}
////- (void) swizzled_viewDidAppear:(BOOL)animated {
////    if ([self respondsToSelector:@selector(swizzled_viewDidAppear:)])
////        [self swizzled_viewDidAppear:animated];
////
////    if ([[DopamineConfiguration current] applicationViews] || [[[DopamineConfiguration current] customViews] objectForKey:NSStringFromClass([self class])]) {
////        [DopamineKit track:@"ApplicationView" metaData:@{@"tag": @"didAppear",
////                                                          @"classname": NSStringFromClass([self class]),
////                                                          @"time": [DopeTimer trackStartTimeFor:[self description]]
////                                                          }];
////    }
////}
////
////- (void) swizzled_viewDidDisappear:(BOOL)animated {
////    if ([self respondsToSelector:@selector(swizzled_viewDidDisappear:)])
////        [self swizzled_viewDidDisappear:animated];
////
////    if ([[DopamineConfiguration current] applicationViews]) {
////        [DopamineKit track:@"ApplicationView" metaData:@{@"tag": @"didDisappear",
////                                                          @"classname": NSStringFromClass([self class]),
////                                                          @"time": [DopeTimer timeTrackedFor:[self description]]
////                                                              }];
////    }
////  }
//
//@end
//
