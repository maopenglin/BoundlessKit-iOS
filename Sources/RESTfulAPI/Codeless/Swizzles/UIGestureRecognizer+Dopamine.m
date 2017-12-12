////
////  UIGestureRecognizer+Dopamine.m
////  Pods
////
////  Created by Akash Desai on 12/11/17.
////
////
//
//#import <UIGestureRecognizer+Dopamine.h>
//
//#import <DopamineKit/DopamineKit-swift.h>
//#import <SwizzleHelper.h>
//
//#import <objc/runtime.h>
//
//@implementation DopamineGestureRecognizer
//
//+ (void) swizzleSelectors {
//    
//    [SwizzleHelper injectSelector:[DopamineGestureRecognizer class] :@selector(swizzled_initWithTarget:action:) :[UITapGestureRecognizer class] :@selector(initWithTarget:action:)];
//    
////    [SwizzleHelper injectSelector:[DopamineViewController class] :@selector(swizzled_viewDidDisappear:) :[UIViewController class] :@selector(viewDidDisappear:)];
//    
//}
//
//- (instancetype) swizzled_initWithTarget:(id)target action:(SEL)action {
//    
//    __block id instance;
//    
//    NSString* targetClassname = @"DrawerItemCell";
//    NSString* selectorName = @"presentChickletListViewController";
//    SEL reinforcedAction = @selector(dopamineTapReinforcement:);
//    
//    if ([target respondsToSelector: reinforcedAction] && NSStringFromClass([target class]) == targetClassname && NSStringFromSelector(action) == selectorName) {
//        instance = [self swizzled_initWithTarget:target action:reinforcedAction];
//    } else {
//        instance = [self swizzled_initWithTarget:target action:action];
//    }
//    
//    return instance;
//}
//
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
////}
//@end

