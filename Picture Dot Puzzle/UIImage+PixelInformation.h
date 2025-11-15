//
//  UIImage+PixelInformation.h
//
//
//  Created by HAI on 12/16/15.
//
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (PixelInformation)

- (BOOL)cornersAreEmpty;
- (nullable UIColor *)colorAtPixel:(CGPoint)point;
- (nullable UIColor *)averageBorderColor;

@end

NS_ASSUME_NONNULL_END
