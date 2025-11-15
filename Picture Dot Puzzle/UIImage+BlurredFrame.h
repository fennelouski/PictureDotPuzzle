//
//  UIImage+blurredFrame.h
//
//  Created by Adrian Gzz on 04/11/13.
//  Copyright (c) 2013 Icalia Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (BlurredFrame)

- (nullable UIImage *)applyLightBluredAtFrame:(CGRect)frame __attribute__((deprecated));

- (nullable UIImage *)applyLightEffectAtFrame:(CGRect)frame;
- (nullable UIImage *)applyExtraLightEffectAtFrame:(CGRect)frame;
- (nullable UIImage *)applyDarkEffectAtFrame:(CGRect)frame;
- (nullable UIImage *)applyTintEffectWithColor:(UIColor *)tintColor atFrame:(CGRect)frame;
- (nullable UIImage *)applyBlurWithRadius:(CGFloat)blurRadius
                                tintColor:(nullable UIColor *)tintColor
                    saturationDeltaFactor:(CGFloat)saturationDeltaFactor
                                maskImage:(nullable UIImage *)maskImage
                                  atFrame:(CGRect)frame;
- (nullable UIImage *)applyBlurWithRadius:(CGFloat)blurRadius
                          iterationsCount:(NSInteger)iterationsCount
                                tintColor:(nullable UIColor *)tintColor
                    saturationDeltaFactor:(CGFloat)saturationDeltaFactor
                                maskImage:(nullable UIImage *)maskImage
                                  atFrame:(CGRect)frame;
+ (nullable UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;
- (nullable id)scaleToSize:(CGSize)newSize;

@end

NS_ASSUME_NONNULL_END
