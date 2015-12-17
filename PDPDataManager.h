//
//  PDPDataManager.h
//  
//
//  Created by HAI on 12/16/15.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PDPDataManager : NSObject

+ (instancetype)sharedDataManager;

@property (nonatomic, strong) UIImage *image;

@property (nonatomic) float cornerRadius;

@property (nonatomic) NSTimeInterval animationDuration;

@property (nonatomic, strong) NSMutableSet *allDots;

- (NSInteger)maximumDivisionLevel;
- (void)setMaximumDivisionLevel:(NSInteger)maximumDivisionLevel;

@end
