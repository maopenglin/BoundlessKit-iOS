//
//  UITapGestureRecognizer+Dopamine.h
//  Pods
//
//  Created by Akash Desai on 12/11/17.
//
//

#ifndef UITapGestureRecognizer_Dopamine_h
#define UITapGestureRecognizer_Dopamine_h

@interface DopamineTapGestureRecognizer : UITapGestureRecognizer

+ (void) swizzleSelectors: (BOOL)enable;

@end

#endif /* UITapGestureRecognizer_Dopamine_h */

