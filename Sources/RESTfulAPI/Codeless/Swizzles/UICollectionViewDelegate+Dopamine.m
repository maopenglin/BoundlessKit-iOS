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

+ (void) swizzleSelectors: (BOOL) enable {
    @synchronized(self) {
        static BOOL didSwizzle = false;
        if (enable ^ didSwizzle) {
            didSwizzle = !didSwizzle;
            [SwizzleHelper injectSelector:[DopamineCollectionViewDelegate class] :@selector(swizzled_setDelegate:) :[UICollectionView class] :@selector(setDelegate:)];
        }
    }
    [DopamineCollectionViewDelegate swizzleDelegateClass:enable];
}


static Class delegateClass = nil;
static NSArray* delegateSubclasses = nil;

+ (void) swizzleDelegateClass:(BOOL) enable {
    if (delegateClass == nil) {
        return;
    }
    
    @synchronized(self) {
        static BOOL didSwizzleDelegate = false;
        if (enable ^ didSwizzleDelegate) {
            didSwizzleDelegate = !didSwizzleDelegate;
            
            [SwizzleHelper injectToProperClass:@selector(swizzled_collectionView:didSelectItemAtIndexPath:) :@selector(collectionView:didSelectItemAtIndexPath:) :delegateSubclasses :[DopamineCollectionViewDelegate class] :delegateClass];
        }
    }
}

- (void) swizzled_setDelegate:(id<UICollectionViewDelegate>)delegate {
    if (delegate && delegateClass == nil) {
        delegateClass = [SwizzleHelper getClassWithProtocolInHierarchy:[delegate class] :@protocol(UICollectionViewDelegate)];
        delegateSubclasses = [SwizzleHelper ClassGetSubclasses:delegateClass];
        [DopamineCollectionViewDelegate swizzleDelegateClass:true];
    }
    
    [self swizzled_setDelegate:delegate];
}

// Did Select Row

- (void)swizzled_collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self) {
        [CodelessAPI submitCollectionViewDidSelectWithTarget:NSStringFromClass([self class]) action:NSStringFromSelector(@selector(collectionView:didSelectItemAtIndexPath:))];
    }
    
    if ([self respondsToSelector:@selector(swizzled_collectionView:didSelectItemAtIndexPath:)]) {
        [self swizzled_collectionView:collectionView didSelectItemAtIndexPath:indexPath];
    }
}

@end
