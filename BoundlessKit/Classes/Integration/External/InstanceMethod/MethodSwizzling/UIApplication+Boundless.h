//
//  UIApplication+Boundless.h
//  Pods
//
//  Created by Akash Desai on 8/15/17.
//
//


#ifndef UIApplication_Boundless_h
#define UIApplication_Boundless_h

@interface BoundlessApp : UIApplication
- (BOOL) notifyMessages__sendAction:(SEL)action to:(id)target from:(id)sender forEvent:(UIEvent *)event;
@end

#endif /* UIApplication_Boundless_h */
