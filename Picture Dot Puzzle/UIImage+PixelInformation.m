//
//  UIImage+PixelInformation.m
//  
//
//  Created by HAI on 12/16/15.
//
//

#import "UIImage+PixelInformation.h"
#import "PDPRenderCore.h"

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
    PDPPixel pixel;
    if (self.size.width <= 0 || self.size.height <= 0 ||
        !PDPSamplePixel(self.CGImage, point.x / self.size.width, point.y / self.size.height, &pixel)) {
        return [UIColor clearColor];
    }
    return [UIColor colorWithRed:pixel.red green:pixel.green blue:pixel.blue alpha:pixel.alpha];
}

- (UIColor *)averageBorderColor {
    NSMutableArray *colors = [NSMutableArray new];
    
    float numberOfDivisions = 50.0f;
    
    CGFloat edgeDistance = 0.001f;
    
    for (int edge = 0; edge < 4; edge++) {
        for (int i = 0; i < numberOfDivisions; i++) {
            CGPoint p = CGPointZero;
            switch (edge) {
                case 0:
                    p.x = self.size.width * edgeDistance;
                    p.y = ((float)i / numberOfDivisions) * self.size.height;
                    break;
                    
                case 1:
                    p.x = self.size.width * (1.0f - edgeDistance);
                    p.y = ((float)i / numberOfDivisions) * self.size.height;
                    break;
                    
                case 2:
                    p.x = ((float)i / numberOfDivisions) * self.size.width;
                    p.y = self.size.height * edgeDistance;
                    break;
                    
                case 3:
                    p.x = ((float)i / numberOfDivisions) * self.size.width;
                    p.y = self.size.height * (1.0f - edgeDistance);
                    break;
                    
                default:
                    break;
            }
            
            [colors addObject:[self colorAtPixel:p]];
        }
    }
    
    CGFloat red, green, blue, hue, saturation, brightness, alpha;
    CGFloat averageRed = 0, averageGreen = 0, averageBlue = 0, averageHue = 0, averageSaturation = 0, averageBrightness = 0, averageAlpha = 0;
    
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
}

@end
