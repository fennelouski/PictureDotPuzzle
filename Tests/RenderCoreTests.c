#include "PDPRenderCore.h"
#include <assert.h>
#include <math.h>
#include <stdio.h>

static void closeTo(double value, double expected) { assert(fabs(value - expected) < 0.02); }

int main(void) {
    // Actual CGImage sampling: top-left red, top-right green, bottom-left blue,
    // bottom-right a half-transparent premultiplied red pixel.
    const unsigned char bytes[] = {255,0,0,255, 0,255,0,255, 0,0,255,255, 128,0,0,128};
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, bytes, sizeof(bytes), NULL);
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGImageRef image = CGImageCreate(2, 2, 8, 32, 8, space,
        kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big, provider, NULL, false, kCGRenderingIntentDefault);
    PDPPixel pixel;
    assert(PDPSamplePixel(image, 0, 0, &pixel)); closeTo(pixel.red, 1); closeTo(pixel.green, 0); closeTo(pixel.blue, 0);
    assert(PDPSamplePixel(image, 0.75, 0.25, &pixel)); closeTo(pixel.green, 1);
    assert(PDPSamplePixel(image, 0.25, 0.75, &pixel)); closeTo(pixel.blue, 1);
    assert(PDPSamplePixel(image, 1, 1, &pixel)); closeTo(pixel.red, 1); closeTo(pixel.alpha, 128.0/255);
    assert(PDPSamplePixel(image, -1, -10, &pixel)); closeTo(pixel.red, 1);
    assert(!PDPSamplePixel(image, NAN, 0, &pixel)); assert(!PDPSamplePixel(NULL, 0, 0, &pixel));
    CGImageRelease(image); CGColorSpaceRelease(space); CGDataProviderRelease(provider);
    puts("PASS: color positions, edge clamping, alpha unpremultiplication and invalid input");

    CGRect parent = CGRectMake(10, 20, 101, 73);
    double area = 0;
    for (unsigned row=0; row<2; row++) for(unsigned column=0;column<2;column++) {
        CGRect child = PDPSubdivisionFrame(parent,row,column);
        assert(CGRectContainsRect(parent,child)); area += child.size.width * child.size.height;
        closeTo(child.origin.x,10+column*50.5); closeTo(child.origin.y,20+row*36.5);
    }
    closeTo(area,parent.size.width*parent.size.height);
    assert(CGRectIsNull(PDPSubdivisionFrame(parent,2,0)));
    puts("PASS: recursive subdivision geometry covers odd-sized offset parent without gaps");

    CGRect landscape=PDPAspectFillRect(CGSizeMake(400,200),CGSizeMake(100,100));
    closeTo(landscape.origin.x,-50);closeTo(landscape.origin.y,0);closeTo(landscape.size.width,200);
    CGRect portrait=PDPAspectFillRect(CGSizeMake(200,400),CGSizeMake(100,100));
    closeTo(portrait.origin.x,0);closeTo(portrait.origin.y,-50);closeTo(portrait.size.height,200);
    assert(CGRectEqualToRect(PDPAspectFillRect(CGSizeZero,CGSizeMake(100,100)),CGRectZero));
    puts("PASS: centered photo crop preserves portrait/landscape aspect ratio");

    assert(PDPDotCount(0)==1);assert(PDPDotCount(1)==5);assert(PDPDotCount(5)==1365);assert(PDPDotCount(6)==5461);
    closeTo(PDPProgress(0,0),0);closeTo(PDPProgress(5461,5461),1);closeTo(PDPProgress(6000,5461),1);
    closeTo(PDPProgress(1,4),0.5);
    puts("PASS: complete quadtree counts and bounded progress including empty state");
    return 0;
}
