//
//  UIApplication+Dopamine.h
//  Pods
//
//  Created by Akash Desai on 8/15/17.
//
//


#ifndef UIApplication_Dopamine_h
#define UIApplication_Dopamine_h

@interface DopamineApp : UIApplication
+ (void) sendActionsToDashboard: (BOOL)enable;
- (BOOL) dashboardIntegration_sendAction:(SEL)action to:(id)target from:(id)sender forEvent:(UIEvent *)event;
@end

#endif /* UIApplication_Dopamine_h */
