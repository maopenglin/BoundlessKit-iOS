//
//  UICollectionViewDelegate+Dopamine.m
//  Pods
//
//  Created by Akash Desai on 8/15/17.
//
//


#import <UICollectionViewDelegate+Dopamine.h>

#import <DopamineKit/DopamineKit-Swift.h>
#import <SwizzleHelper.h>

#import <objc/runtime.h>

@implementation DopamineCollectionViewDelegate

+ (void) enhanceSelectors: (BOOL) enable {
    @synchronized(self) {
        static BOOL didEnhance = false;
        if (enable ^ didEnhance) {
            didEnhance = !didEnhance;
            [SwizzleHelper injectSelector:[DopamineCollectionViewDelegate class] :@selector(enhanced_setDelegate:) :[UICollectionView class] :@selector(setDelegate:)];
        }
    }
    [DopamineCollectionViewDelegate enhanceDelegateClass:enable];
}


static Class delegateClass = nil;
static NSArray* delegateSubclasses = nil;

+ (void) enhanceDelegateClass:(BOOL) enable {
    if (delegateClass == nil) {
        return;
    }
    
    @synchronized(self) {
        static BOOL didEnhanceDelegate = false;
        if (enable ^ didEnhanceDelegate) {
            didEnhanceDelegate = !didEnhanceDelegate;
            
            [SwizzleHelper injectToProperClass:@selector(enhanced_collectionView:didSelectItemAtIndexPath:) :@selector(collectionView:didSelectItemAtIndexPath:) :delegateSubclasses :[DopamineCollectionViewDelegate class] :delegateClass];
        }
    }
}

- (void) enhanced_setDelegate:(id<UICollectionViewDelegate>)delegate {
    if (delegate && delegateClass == nil) {
        delegateClass = [SwizzleHelper getClassWithProtocolInHierarchy:[delegate class] :@protocol(UICollectionViewDelegate)];
        delegateSubclasses = [SwizzleHelper ClassGetSubclasses:delegateClass];
        [DopamineCollectionViewDelegate enhanceDelegateClass:true];
    }
    
    [self enhanced_setDelegate:delegate];
}

// Did Select Row

- (void)enhanced_collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self) {
        [CodelessAPI submitWithTargetInstance:self selector:@selector(collectionView:didSelectItemAtIndexPath:)];
    }
    
    if ([self respondsToSelector:@selector(enhanced_collectionView:didSelectItemAtIndexPath:)]) {
        [self enhanced_collectionView:collectionView didSelectItemAtIndexPath:indexPath];
    }
}

@end
