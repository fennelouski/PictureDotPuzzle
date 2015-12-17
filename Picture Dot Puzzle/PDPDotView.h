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

- (void)removeSubdivisions;

@end
