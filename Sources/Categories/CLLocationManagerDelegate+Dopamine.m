////
////  CLLocationManagerDelegate+Dopamine.m
////  DopamineKit
////
////  Created by Akash Desai on 11/9/17.
////
//
//#import "CLLocationManagerDelegate+Dopamine.h"
//
//#import <DopamineKit/DopamineKit-Swift.h>
//#import <SwizzleHelper.h>
//
//#import <CoreLocation/CoreLocation.h>
//
//@implementation DopamineLocationManagerDelegate
//
//+ (void) swizzleSelectors {
//    [SwizzleHelper injectSelector:[DopamineLocationManagerDelegate class] :@selector(swizzled_setDelegate:) :[CLLocationManager class] :@selector(setDelegate:)];
//}
//
//static Class delegateClass = nil;
//static NSArray* delegateSubclasses = nil;
//
//+ (Class) delegateClass {
//    return delegateClass;
//}
//
//- (void) swizzled_setDelegate:(id<CLLocationManagerDelegate>)delegate {
//    if (delegateClass) {
//        [self swizzled_setDelegate:delegate];
//        return;
//    }
//    
//    Class swizzledClass = [DopamineLocationManagerDelegate class];
//    delegateClass = [SwizzleHelper getClassWithProtocolInHierarchy:[delegate class] :@protocol(CLLocationManagerDelegate)];
//    delegateSubclasses = [SwizzleHelper ClassGetSubclasses:delegateClass];
//    
//    [SwizzleHelper injectToProperClass:@selector(swizzled_locationManager:didUpdateLocations:) :@selector(locationManager:didUpdateLocations:) :delegateSubclasses :swizzledClass :delegateClass];
//    
//    [self swizzled_setDelegate:delegate];
//}
//
//- (void)swizzled_locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
//    if ([self respondsToSelector:@selector(swizzled_locationManager:didUpdateLocations:)])
//        [self swizzled_locationManager:manager didUpdateLocations:locations];
//    
//    if ([[DopeConfig shared] locationObservations]) {
//        NSLog(@"In didUpdateLocations");
//        //    [DopamineKit track:@"CLLocationManagerDelegate" locations:locations];
//    } else {
//        NSLog(@"In didUpdateLocations but locationObservations disabled");
//    }
//}
//
//- (void)swizzled_locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
//    if ([self respondsToSelector:@selector(swizzled_locationManager:didUpdateHeading:)])
//        [self swizzled_locationManager:manager didUpdateHeading:newHeading];
//    
//    if ([[DopeConfig shared] locationObservations]) {
//        NSLog(@"In didUpdateHeading");
//    } else {
//        NSLog(@"In didUpdateHeading but locationObservations disabled");
//    }
//}
//
//- (void)swizzled_locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
//    if ([self respondsToSelector:@selector(swizzled_locationManager:didEnterRegion:)])
//        [self swizzled_locationManager:manager didEnterRegion:region];
//    
//    [DopamineKit track:@"CoreLocation" metaData:@{@"tag": @"didEnterRegion",
//                                                  @"classname": NSStringFromClass([self class]),
//                                                  @"regionID": [region identifier]
//                                                  }];
//}
//
//@end

