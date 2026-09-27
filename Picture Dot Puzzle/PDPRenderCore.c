#include "PDPRenderCore.h"
#include <math.h>

bool PDPSamplePixel(CGImageRef image, CGFloat x, CGFloat y, PDPPixel *pixel) {
    if (!image || !pixel || !isfinite(x) || !isfinite(y)) return false;
    size_t width = CGImageGetWidth(image), height = CGImageGetHeight(image);
    if (!width || !height) return false;
    size_t px = (size_t)fmin(width - 1, floor(fmax(0, x) * width));
    size_t py = (size_t)fmin(height - 1, floor(fmax(0, y) * height));
    unsigned char bytes[4] = {0};
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(bytes, 1, 1, 8, 4, space,
        kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(space);
    if (!context) return false;
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    CGContextSetInterpolationQuality(context, kCGInterpolationNone);
    CGContextTranslateCTM(context, -(CGFloat)px, (CGFloat)py - (CGFloat)height + 1);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
    CGContextRelease(context);
    CGFloat alpha = bytes[3] / 255.0;
    *pixel = (PDPPixel){alpha ? fmin(1, bytes[0] / 255.0 / alpha) : 0,
                       alpha ? fmin(1, bytes[1] / 255.0 / alpha) : 0,
                       alpha ? fmin(1, bytes[2] / 255.0 / alpha) : 0, alpha};
    return true;
}

CGRect PDPSubdivisionFrame(CGRect parent, unsigned row, unsigned column) {
    if (row > 1 || column > 1) return CGRectNull;
    return CGRectMake(parent.origin.x + column * parent.size.width / 2,
                      parent.origin.y + row * parent.size.height / 2,
                      parent.size.width / 2, parent.size.height / 2);
}

CGRect PDPAspectFillRect(CGSize source, CGSize destination) {
    if (source.width <= 0 || source.height <= 0 || destination.width <= 0 || destination.height <= 0)
        return CGRectZero;
    CGFloat scale = fmax(destination.width / source.width, destination.height / source.height);
    CGSize size = CGSizeMake(source.width * scale, source.height * scale);
    return CGRectMake((destination.width - size.width) / 2,
                      (destination.height - size.height) / 2, size.width, size.height);
}

size_t PDPDotCount(unsigned maximumLevel) {
    maximumLevel = maximumLevel > 8 ? 8 : maximumLevel;
    size_t count = 1, levelCount = 1;
    for (unsigned level = 1; level <= maximumLevel; level++) { levelCount *= 4; count += levelCount; }
    return count;
}

double PDPProgress(size_t created, size_t total) {
    return total ? sqrt(fmin(1, (double)created / total)) : 0;
}
