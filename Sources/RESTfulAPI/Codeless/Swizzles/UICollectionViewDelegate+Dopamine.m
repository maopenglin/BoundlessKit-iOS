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

+ (void) swizzleSelectors {
    
#if DEBUG
    
    [SwizzleHelper injectSelector:[DopamineCollectionViewDelegate class] :@selector(swizzled_setDelegate:) :[UICollectionView class] :@selector(setDelegate:)];
    
#endif
    
}

//+ (void) dopamineLoadedTagSelector {}

static Class delegateClass = nil;

// Store an array of all UIAppDelegate subclasses to iterate over in cases where UIAppDelegate swizzled methods are not overriden in main AppDelegate
// But rather in one of the subclasses
static NSArray* delegateSubclasses = nil;

+ (Class) delegateClass {
    return delegateClass;
}

- (void) swizzled_setDelegate:(id<UICollectionViewDelegate>)delegate {
    if (delegateClass) {
        [self swizzled_setDelegate:delegate];
        return;
    }
    
    Class swizzledClass = [DopamineCollectionViewDelegate class];
    delegateClass = [SwizzleHelper getClassWithProtocolInHierarchy:[delegate class] :@protocol(UICollectionViewDelegate)];
    delegateSubclasses = [SwizzleHelper ClassGetSubclasses:delegateClass];
    
    [SwizzleHelper injectToProperClass:@selector(swizzled_collectionView:didSelectItemAtIndexPath:) :@selector(collectionView:didSelectItemAtIndexPath:) :delegateSubclasses :swizzledClass :delegateClass];
    
    [self swizzled_setDelegate:delegate];
}

// Did Select Row

- (void)swizzled_collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [CodelessAPI submitCollectionViewDidSelectWithTarget:NSStringFromClass([self class]) action:NSStringFromSelector(@selector(collectionView:didSelectItemAtIndexPath:))];
    
    if ([self respondsToSelector:@selector(swizzled_collectionView:didSelectItemAtIndexPath:)]) {
        [self swizzled_collectionView:collectionView didSelectItemAtIndexPath:indexPath];
    }
}

@end
