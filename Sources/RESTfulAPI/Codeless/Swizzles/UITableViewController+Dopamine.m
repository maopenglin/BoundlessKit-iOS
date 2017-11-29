////
////  UIViewController+Dopamine.m
////  Pods
////
////  Created by Akash Desai on 8/16/17.
////
////
//
//#import <UITableViewController+Dopamine.h>
//
//#import <DopamineKit/DopamineKit-swift.h>
//#import <SwizzleHelper.h>
//
//#import <objc/runtime.h>
//
//@implementation DopamineTableViewController
//
//+ (void) swizzleSelectors {
//    [SwizzleHelper injectSelector:[DopamineTableViewController class] :@selector(swizzled_tableView:didSelectRowAtIndexPath:) :[UIViewController class] :@selector(tableView:didSelectRowAtIndexPath:)];
//}
//
//- (void)swizzled_tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    
////    [[tableView cellForRowAtIndexPath:indexPath] showGrowObjcWithCompletionHandler:^{
////        if ([self respondsToSelector:@selector(swizzled_tableView:didSelectRowAtIndexPath:)])
////        [self swizzled_tableView:tableView didSelectRowAtIndexPath:indexPath];
////    }];
//    
////    [self shrinkAllRowsFor:indexPath completion:^{
////        if ([self respondsToSelector:@selector(swizzled_tableView:didSelectRowAtIndexPath:)])
////        [self swizzled_tableView:tableView didSelectRowAtIndexPath:indexPath];
////    }];
//    
////    BOOL completionSent = false;
////    for (int i = 0; i < [tableView numberOfRowsInSection:indexPath.section]; i++) {
////        if (!completionSent) {
////            [[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:indexPath.section]] showGrowObjcWithCompletionHandler:^{
////                if ([self respondsToSelector:@selector(swizzled_tableView:didSelectRowAtIndexPath:)])
////                [self swizzled_tableView:tableView didSelectRowAtIndexPath:indexPath];
////            }]
////            completionSent = true;
////        } else {
////            [[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:indexPath.section]] showGrowObjcWithCompletionHandler:^{
////
////            }]
////        }
////    }
//    
//    
////    if ([self respondsToSelector:@selector(swizzled_tableView:didSelectRowAtIndexPath:)])
////    [self swizzled_tableView:tableView didSelectRowAtIndexPath:indexPath];
//    for (int i = 0; i < [tableView numberOfRowsInSection:indexPath.section]; i++) {
//        [[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:indexPath.section]] showGrowObjcWithCompletionHandler:^{
//        }];
//    }
//
//}
//@end

