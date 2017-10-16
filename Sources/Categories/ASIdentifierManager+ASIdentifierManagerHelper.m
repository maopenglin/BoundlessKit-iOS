//
//  ASIdentifierManager+ASIdentifierManagerHelper.m
//  DopamineKit
//
//  Created by Akash Desai on 10/12/17.
//

#import "ASIdentifierManager+ASIdentifierManagerHelper.h"

@implementation ASIdentifierManager (ASIdentifierManagerHelper)
- (nullable NSUUID*) adId {
    return [self advertisingIdentifier];
}
@end
