////
////  DopeLocation.m
////  DopamineKit
////
////  Created by Akash Desai on 11/9/17.
////
//
//#import "DopeLocation.h"
//
//#import <DopamineKit/DopamineKit-Swift.h>
//
//#import <CoreLocation/CoreLocation.h>
//
//@implementation DopeLocation
//
////Track time until next location fire event
//const NSTimeInterval foregroundSendLocationWaitTime = 5;// * 60.0;
//const NSTimeInterval backgroundSendLocationWaitTime = 9.75;// * 60.0;
//NSTimer* sendLocationTimer = nil;
//dl_last_location *lastLocation;
//bool initialLocationSent = false;
//UIBackgroundTaskIdentifier fcTask;
//
//static id locationManager = nil;
//static bool started = false;
//static bool hasDelayed = false;
//
//NSObject *_mutexObjectForLastLocation;
//+(NSObject*)mutexObjectForLastLocation {
//    if (!_mutexObjectForLastLocation)
//        _mutexObjectForLastLocation = [NSObject alloc];
//    return _mutexObjectForLastLocation;
//}
//
//static DopeLocation* singleInstance = nil;
//+(DopeLocation*) sharedInstance {
//    @synchronized( singleInstance ) {
//        if( !singleInstance ) {
//            singleInstance = [[DopeLocation alloc] init];
//        }
//    }
//    
//    return singleInstance;
//}
//
//+ (dl_last_location*)lastLocation {
//    return lastLocation;
//}
//+ (void)clearLastLocation {
//    @synchronized(DopeLocation.mutexObjectForLastLocation) {
//        lastLocation = nil;
//    }
//}
//
//+ (void) getLocation:(bool)prompt {
//    if (hasDelayed)
//        [DopeLocation internalGetLocation:prompt];
//    else {
//        // Delay required for locationServicesEnabled and authorizationStatus return the correct values when CoreLocation is not statically linked.
//        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
//        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
//            hasDelayed = true;
//            [DopeLocation internalGetLocation:prompt];
//        });
//    }
//    
//    //Listen to app going to and from background
//}
//
//+ (void)onfocus:(BOOL)isActive {
//    if(!locationManager || !started) {
//        if (!locationManager) {
//            NSLog(@"No location manager created yet");
//        }
//        if (!started) {
//            NSLog(@"DopeLocation tracking not started yet");
//        }
//        return;
//    }
//    /**
//     We have a state switch
//     - If going to active: keep timer going
//     - If going to background:
//     1. Make sure that we can track background location
//     -> continue timer to send location otherwise set location to nil
//     Otherwise set timer to NULL
//     **/
//    
//    
//    NSTimeInterval remainingTimerTime = sendLocationTimer.fireDate.timeIntervalSinceNow;
//    NSTimeInterval requiredWaitTime = isActive ? foregroundSendLocationWaitTime : backgroundSendLocationWaitTime ;
//    NSTimeInterval adjustedTime = remainingTimerTime > 0 ? remainingTimerTime : requiredWaitTime;
//    
//    if(isActive) {
//        if(sendLocationTimer && initialLocationSent) {
//            //Keep timer going with the remaining time
//            [sendLocationTimer invalidate];
//            sendLocationTimer = [NSTimer scheduledTimerWithTimeInterval:adjustedTime target:self selector:@selector(sendLocation) userInfo:nil repeats:NO];
//        }
//    }
//    else {
//        
//        //Check if always granted
//        if( (int)[NSClassFromString(@"CLLocationManager") performSelector:@selector(authorizationStatus)] == 3) {
//            [DopeLocation beginTask];
//            [sendLocationTimer invalidate];
//            sendLocationTimer = [NSTimer scheduledTimerWithTimeInterval:adjustedTime target:self selector:@selector(sendLocation) userInfo:nil repeats:NO];
//            [[NSRunLoop mainRunLoop] addTimer:sendLocationTimer forMode:NSRunLoopCommonModes];
//        }
//        else sendLocationTimer = NULL;
//    }
//}
//
//+ (void) beginTask {
//    fcTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
//        [DopeLocation endTask];
//    }];
//}
//
//+ (void) endTask {
//    [[UIApplication sharedApplication] endBackgroundTask: fcTask];
//    fcTask = UIBackgroundTaskInvalid;
//}
//
//
//
//+ (void) internalGetLocation:(bool)prompt {
//    if (started) {
//        NSLog(@"DopeLocation already started.");
//        return;
//    }
//    
//    id clLocationManagerClass = [CLLocationManager class];// NSClassFromString(@"CLLocationManager");
//    
//    // Check for location in plist
//    if (![clLocationManagerClass performSelector:@selector(locationServicesEnabled)]) {
//        NSLog(@"No location services enabled in info.plist");
//        return;
//    }
//    
//    if ([clLocationManagerClass performSelector:@selector(authorizationStatus)] == 0 && !prompt) {
//        NSLog(@"Permission denied for location");
//        return;
//    }
//    
//    locationManager = [[clLocationManagerClass alloc] init];
//    [locationManager setValue:[self sharedInstance] forKey:@"delegate"];
//    
//    
//    //Check info plist for request descriptions
//    //LocationAlways > LocationWhenInUse > No entry (Log error)
//    //Location Always requires: Location Background Mode + NSLocationAlwaysUsageDescription
//    NSArray* backgroundModes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIBackgroundModes"];
//    NSString* alwaysDescription = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysUsageDescription"];
//    if(backgroundModes && [backgroundModes containsObject:@"location"] && alwaysDescription) {
//        [locationManager performSelector:@selector(requestAlwaysAuthorization)];
//        [locationManager setValue:@YES forKey:@"allowsBackgroundLocationUpdates"];
//    }
//    
//    else if([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationWhenInUseUsageDescription"])
//        [locationManager performSelector:@selector(requestWhenInUseAuthorization)];
//    
//    else NSLog(@"Include a privacy NSLocationAlwaysUsageDescription or NSLocationWhenInUseUsageDescription in your info.plist to request location permissions.");
//    
//    
//    started = true;
//}
//#pragma mark CLLocationManagerDelegate
//
//- (void)locationManager:(id)manager didUpdateLocations:(NSArray *)locations {
//    
//    [manager performSelector:@selector(stopUpdatingLocation)];
//    
//    id location = locations.lastObject;
//    
//    SEL cord_selector = NSSelectorFromString(@"coordinate");
//    dl_location_coordinate cords;
//    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[[location class] instanceMethodSignatureForSelector:cord_selector]];
//    
//    [invocation setTarget:locations.lastObject];
//    [invocation setSelector:cord_selector];
//    [invocation invoke];
//    [invocation getReturnValue:&cords];
//    
//    dl_last_location *currentLocation = (dl_last_location*)malloc(sizeof(dl_last_location));
//    currentLocation->verticalAccuracy = [[location valueForKey:@"verticalAccuracy"] doubleValue];
//    currentLocation->horizontalAccuracy = [[location valueForKey:@"horizontalAccuracy"] doubleValue];
//    currentLocation->cords = cords;
//    
//    @synchronized(DopeLocation.mutexObjectForLastLocation) {
//        lastLocation = currentLocation;
//    }
//    
//    if(!sendLocationTimer)
//        [DopeLocation resetSendTimer];
//    
//    if(!initialLocationSent)
//        [DopeLocation sendLocation];
//    
//}
//
//+ (void)resetSendTimer {
//    NSTimeInterval requiredWaitTime = [UIApplication sharedApplication].applicationState == UIApplicationStateActive ? foregroundSendLocationWaitTime : backgroundSendLocationWaitTime ;
//    sendLocationTimer = [NSTimer scheduledTimerWithTimeInterval:requiredWaitTime target:self selector:@selector(sendLocation) userInfo:nil repeats:NO];
//}
//
//+ (void)sendLocation {
//    @synchronized(DopeLocation.mutexObjectForLastLocation) {
//        if (!lastLocation) {
//            NSLog(@"No last location");
//            return;
//        } else {
//            NSLog(@"Sending last location...");
//        }
//        
//        //Fired from timer and not initial location fetched
//        if (initialLocationSent)
//            [DopeLocation resetSendTimer];
//        
//        initialLocationSent = YES;
//        
//        BOOL logBG = [UIApplication sharedApplication].applicationState != UIApplicationStateActive;
//        
//        [DopamineKit track:@"DopeLocation" metaData: [NSDictionary dictionaryWithObjectsAndKeys:
//                                 @(lastLocation->cords.latitude), @"lat",
//                                 @(lastLocation->cords.longitude), @"long",
//                                 @(lastLocation->verticalAccuracy), @"locationVerticalAccuracy",
//                                 @(lastLocation->horizontalAccuracy), @"locationHorizontalAccuracy",
//                                 @(logBG), @"locationBackground",
//                                 nil]];
//    }
//}
//
//@end
//
