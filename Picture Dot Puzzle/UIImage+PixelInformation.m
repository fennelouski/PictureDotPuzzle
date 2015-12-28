//
//  UIImage+PixelInformation.m
//  
//
//  Created by HAI on 12/16/15.
//
//

#import "UIImage+PixelInformation.h"

@implementation UIImage (PixelInformation)

- (BOOL)cornersAreEmpty {
    CGFloat insetAmount = 7.0f;
    CGPoint topLeft = CGPointMake(insetAmount, insetAmount);
    CGPoint topRight = CGPointMake(self.size.width - insetAmount, insetAmount);
    CGPoint bottomLeft = CGPointMake(insetAmount, self.size.height - insetAmount);
    CGPoint bottomRight = CGPointMake(self.size.width - insetAmount, self.size.height - insetAmount);
    
    NSArray *points = @[[NSValue valueWithCGPoint:topLeft],
                        [NSValue valueWithCGPoint:topRight],
                        [NSValue valueWithCGPoint:bottomLeft],
                        [NSValue valueWithCGPoint:bottomRight]];
    
    for (NSValue *pointValue in points) {
        CGPoint point = [pointValue CGPointValue];
        
        UIColor *color = [self colorAtPixel:point];
        
        if (!color) {
            NSLog(@"Missing point (%f, %f) is outside of size w: %f\th: %f", point.x, point.y, self.size.width, self.size.height);
            break;
        }
        
        CGFloat red, green, blue, alpha;
        [color getRed:&red green:&green blue:&blue alpha:&alpha];
        
        CGFloat alphaThreshold  = 0.2f;
        CGFloat redThreshold    = 0.925f;
        CGFloat greenThreshold  = 0.9f;
        CGFloat blueThreshold   = 0.95f;
        
        if (alpha > alphaThreshold && (red < redThreshold && green < greenThreshold && blue < blueThreshold)) {
            return NO;
        }
    }
    
    return YES;
}

- (UIColor *)colorAtPixel:(CGPoint)point {
    if (!CGRectContainsPoint(CGRectMake(0.0f, 0.0f, self.size.width, self.size.height), point)) {
        return [UIColor clearColor];
    }
    
    // Create a 1x1 pixel byte array and bitmap context to draw the pixel into.
    NSInteger pointX = trunc(point.x);
    NSInteger pointY = trunc(point.y);
    CGImageRef cgImage = self.CGImage;
    NSUInteger width = self.size.width;
    NSUInteger height = self.size.height;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    int bytesPerPixel = 4;
    int bytesPerRow = bytesPerPixel * 1;
    NSUInteger bitsPerComponent = 8;
    unsigned char pixelData[4] = { 0, 0, 0, 0 };
    CGContextRef context = CGBitmapContextCreate(pixelData, 1, 1, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    
    // Draw the pixel we are interested in onto the bitmap context
    CGContextTranslateCTM(context, -pointX, pointY-(CGFloat)height);
    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, (CGFloat)width, (CGFloat)height), cgImage);
    CGContextRelease(context);
    
    // Convert color values [0..255] to floats [0.0..1.0]
    CGFloat red   = (CGFloat)pixelData[0] / 255.0f;
    CGFloat green = (CGFloat)pixelData[1] / 255.0f;
    CGFloat blue  = (CGFloat)pixelData[2] / 255.0f;
    CGFloat alpha = (CGFloat)pixelData[3] / 255.0f;
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

- (UIColor *)averageBorderColor {
    NSMutableSet *colors = [NSMutableSet new];
    
    float numberOfDivisions = 10.0f;
    
    for (int edge = 0; edge < 4; edge++) {
        for (int i = 0; i < numberOfDivisions; i++) {
            CGPoint p = CGPointZero;
            switch (edge) {
                case 0:
                    p.x = 0;
                    p.y = ((float)i / numberOfDivisions) * self.size.height;
                    break;
                    
                case 1:
                    p.x = self.size.width;
                    p.y = ((float)i / numberOfDivisions) * self.size.height;
                    break;
                    
                case 2:
                    p.x = ((float)i / numberOfDivisions) * self.size.width;
                    p.y = 0;
                    break;
                    
                case 3:
                    p.x = ((float)i / numberOfDivisions) * self.size.width;
                    p.y = self.size.height;
                    break;
                    
                default:
                    break;
            }
            
            [colors addObject:[self colorAtPixel:p]];
        }
    }
    
    CGFloat red, green, blue, hue, saturation, brightness, alpha;
    CGFloat averageRed, averageGreen, averageBlue, averageHue, averageSaturation, averageBrightness, averageAlpha;
    
    for (UIColor *color in colors) {
        [color getRed:&red
                green:&green
                 blue:&blue
                alpha:&alpha];
        averageRed += red;
        averageGreen += green;
        averageBlue += blue;
        averageAlpha += alpha;
        
        [color getHue:&hue
           saturation:&saturation
           brightness:&brightness
                alpha:&alpha];
        averageHue += hue;
        averageSaturation += saturation;
        averageBrightness += brightness;
        averageAlpha += alpha;
    }
    
    averageRed /= colors.count;
    averageGreen /= colors.count;
    averageBlue /= colors.count;
    averageHue /= colors.count;
    averageSaturation /= colors.count;
    averageBrightness /= colors.count;
    averageAlpha /= 2.0f * colors.count;
    
    if (averageBrightness > 0.5f) {
        averageBrightness *= 0.25f;
    } else {
        averageBrightness = 1.0f - ((1.0f - averageBrightness) * 0.25f);
    }
    
    return [UIColor colorWithHue:averageHue
                      saturation:averageSaturation
                      brightness:averageBrightness
                           alpha:1.0f];
    
    return [UIColor colorWithRed:averageRed
                           green:averageGreen
                            blue:averageBlue
                           alpha:averageAlpha];
}

@end
