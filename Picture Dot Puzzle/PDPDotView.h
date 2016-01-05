//
//  PDPDotView.h
//  
//
//  Created by HAI on 12/16/15.
//
//

#import <UIKit/UIKit.h>

@interface PDPDotView : UIButton

@property (nonatomic) BOOL isDivided;

@property (nonatomic, strong) UIView *rootView;

@property (nonatomic) NSInteger divisionLevel;

@property (nonatomic) NSInteger dotNumber;

/**
 *  The center of the dot as a value between 0 and 1 relative to the dot container.
 */
@property (nonatomic) CGPoint relativeCenter;

@property (nonatomic) CGSize relativeSize;

- (void)layoutSubviewsOnMainThread;

- (void)removeSubdivisions;

@end
