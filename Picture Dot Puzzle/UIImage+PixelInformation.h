//
//  UIImage+PixelInformation.h
//  
//
//  Created by HAI on 12/16/15.
//
//

#import <UIKit/UIKit.h>

@interface UIImage (PixelInformation)

- (BOOL)cornersAreEmpty;
- (UIColor *)colorAtPixel:(CGPoint)point;
- (UIColor *)averageBorderColor;

@end
