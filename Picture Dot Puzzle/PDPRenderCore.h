#ifndef PDP_RENDER_CORE_H
#define PDP_RENDER_CORE_H
#include <CoreGraphics/CoreGraphics.h>
#include <stdbool.h>
#include <stddef.h>

typedef struct { CGFloat red, green, blue, alpha; } PDPPixel;
bool PDPSamplePixel(CGImageRef image, CGFloat normalizedX, CGFloat normalizedY, PDPPixel *pixel);
CGRect PDPSubdivisionFrame(CGRect parent, unsigned row, unsigned column);
CGRect PDPAspectFillRect(CGSize source, CGSize destination);
size_t PDPDotCount(unsigned maximumLevel);
double PDPProgress(size_t created, size_t total);
#endif
