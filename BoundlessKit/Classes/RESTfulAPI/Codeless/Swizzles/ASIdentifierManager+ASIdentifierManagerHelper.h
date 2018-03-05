//
//  ASIdentifierManager+ASIdentifierManagerHelper.h
//  BoundlessKit
//
//  Created by Akash Desai on 10/12/17.
//

#import <Foundation/Foundation.h>
#import <AdSupport/ASIdentifierManager.h>

@interface ASIdentifierManager (ASIdentifierManagerHelper)
- (nullable NSUUID*) adId;
@end
