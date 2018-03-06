//
//  UIViewController+Dopamine.h
//  Pods
//
//  Created by Akash Desai on 8/16/17.
//
//

#ifndef UIViewController_Dopamine_h
#define UIViewController_Dopamine_h

@interface DopamineViewController : UIViewController

+ (void) sendViewDidAppearToDashboard: (BOOL)enable;
- (void) dashboardIntegration_viewDidAppear:(BOOL)animated;

@end

#endif /* UIViewController_Dopamine_h */
