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

/**
 *  The RATIO of the corner radius. Implemented corner radius is relative to the view it's bein applied to, but the ratio is instantaneous and global. Changing this value does not retroactively update views that have already used this value to set their corner radius.
 */
@property (nonatomic) float cornerRadius;

/**
 *  The default amount of time each individual animation takes.
 *  Example animations: subdivisions moving to their correct location, toolbars showing/hiding, status bar showing/hiding
 */
@property (nonatomic) NSTimeInterval animationDuration;

/**
 *  The amount of time the initial randomized animation takes.
 */
@property (nonatomic) NSTimeInterval automationDuration;



/**
 *  The collection of all dots currently on screen.
 */
@property (nonatomic, strong) NSHashTable *allDots;
@property (nonatomic) BOOL canMutateAllDots;
@property (nonatomic) NSHashTable *reserveDots;

/**
 *
 *
 *  @return The number of times the root dot can be split into smaller dots
 */
- (NSInteger)maximumDivisionLevel;
- (void)setMaximumDivisionLevel:(NSInteger)maximumDivisionLevel;

@property (nonatomic) NSInteger dotNumber;
- (NSInteger)totalNumberOfDotsPossible;
- (float)progress;

/**
 *  When this image is changed, dots are NOT reset. This allows the user to combine different dots from different images and create their own collage.
 *
 *  @return The image being used to create new dots
 */
- (UIImage *)image;
- (void)setImage:(UIImage *)image;




- (NSString *)deviceType;

@end
