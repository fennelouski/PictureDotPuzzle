//
//  PDPDotView.m
//  
//
//  Created by HAI on 12/16/15.
//
//

#import "PDPDotView.h"
#import "PDPDataManager.h"
#import "UIImage+PixelInformation.h"

@interface PDPDotView ()

@property (nonatomic, strong) NSMutableArray *subdivisions;

@property (nonatomic, strong) UITapGestureRecognizer *tap;
@property (nonatomic, strong) UISwipeGestureRecognizer *swipe;
@property (nonatomic, strong) UIPanGestureRecognizer *pan;

@property (nonatomic) BOOL layoutColor;

@end

static NSInteger const numberOfSubdivisions = 2;

@implementation PDPDotView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self addTarget:self
                 action:@selector(dragged:)
       forControlEvents:UIControlEventTouchDragEnter | UIControlEventTouchDragExit];
        
        self.dotNumber = [PDPDataManager sharedDataManager].dotNumber++;
        
        self.layoutColor = YES;
    }
    
    return self;
}

- (void)layoutSubviewsOnMainThread {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self layoutSubviews];
    });
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.layer.cornerRadius = self.frame.size.width * [[PDPDataManager sharedDataManager] cornerRadius];
    
    if (self.isDivided) {
        self.clipsToBounds = NO;
        
        if (self.divisionLevel < [PDPDataManager sharedDataManager].maximumDivisionLevel) {
            [self layoutSubdivisions];
            self.backgroundColor = [UIColor clearColor];
        }

        [self removeGestureRecognizer:self.tap];
        [self removeGestureRecognizer:self.swipe];
        [self removeGestureRecognizer:self.pan];
    } else {
        self.clipsToBounds = YES;
        [self addGestureRecognizer:self.tap];
        [self addGestureRecognizer:self.swipe];
        [self addGestureRecognizer:self.pan];
        
        if (self.layoutColor) {
            self.backgroundColor = [self colorAtCenter];
        }
    }
}

- (UIColor *)colorAtCenter {
    CGPoint center = self.center;
    
    return [self colorAtPoint:center];
}

- (UIColor *)colorAtPoint:(CGPoint)center {
    CGPoint relativeCenter = CGPointMake(center.x / self.rootView.frame.size.width,
                                         center.y / self.rootView.frame.size.height);
    UIImage *sourceImage = [[PDPDataManager sharedDataManager] image];
    
    if (sourceImage.size.width == 0.0f || sourceImage.size.height == 0.0f) { // avoids division by 0
        return [UIColor colorWithRed:relativeCenter.x
                               green:relativeCenter.y
                                blue:relativeCenter.x * 0.5f + relativeCenter.y * 0.5f
                               alpha:1.0f];
    }
    
    // center of this dot in the image size
    CGPoint actualCenter = CGPointMake(relativeCenter.x * sourceImage.size.width,
                                       relativeCenter.y * sourceImage.size.height);
    
    return [[[PDPDataManager sharedDataManager] image] colorAtPixel:actualCenter];
}

- (void)layoutSubdivisions {
    if (!self.subdivisions) {
        self.subdivisions = [NSMutableArray new];
        
        for (int row = 0; row < numberOfSubdivisions; row++) {
            for (int column = 0; column < numberOfSubdivisions; column++) {
                PDPDotView *dot = [[PDPDotView alloc] initWithFrame:self.frame];
                dot.rootView = self.rootView;
                dot.backgroundColor = self.backgroundColor;
                
                CGRect finalFrame = [self frameForRow:row
                                               column:column];
                
                CGPoint finalFrameCenter = CGPointMake(finalFrame.origin.x + finalFrame.size.width * 0.5f,
                                                       finalFrame.origin.y + finalFrame.size.height * 0.5f);
                
                if ([PDPDataManager sharedDataManager].cornerRadius == 0.5f) {
                    CGPoint startingCenter = CGPointMake((finalFrameCenter.x + dot.center.x) * 0.5f,
                                                         (finalFrameCenter.y + dot.center.y) * 0.5f);
                    CGFloat scale = 0.55f;
                    dot.frame = CGRectMake(0.0f,
                                           0.0f,
                                           self.frame.size.width * scale,
                                           self.frame.size.height * scale);
                    dot.center = startingCenter;
                    
                    [UIView animateWithDuration:(self.divisionLevel > 4) ? 0.0f : [[PDPDataManager sharedDataManager] animationDuration]
                                     animations:^{
                                         dot.frame = finalFrame;
                                         self.backgroundColor = [self colorAtPoint:finalFrameCenter];
                                     }];
                } else {
                    [UIView animateWithDuration:(self.divisionLevel > 4) ? 0.0f : [[PDPDataManager sharedDataManager] animationDuration]
                                     animations:^{
                                         dot.frame = [self frameForRow:row
                                                                column:column];
                                         self.backgroundColor = [self colorAtPoint:finalFrameCenter];
                                     }];
                }
                
                dot.divisionLevel = self.divisionLevel + 1;
                if (dot.divisionLevel < [PDPDataManager sharedDataManager].maximumDivisionLevel) {
                    if ([PDPDataManager sharedDataManager].canMutateAllDots) {
                        [[PDPDataManager sharedDataManager].allDots addObject:dot];
                    } else {
                        [[PDPDataManager sharedDataManager].reserveDots addObject:dot];
                        NSLog(@"Reserve count: %zd", [PDPDataManager sharedDataManager].reserveDots.count);
                    }
                }
                
                [self.subdivisions addObject:dot];
                [self.rootView addSubview:dot];
            }
        }
        
        [[PDPDataManager sharedDataManager].allDots removeObject:self];
    }
    
    if (self.subdivisions.count > 0) {
        PDPDotView *subDotView = [self.subdivisions objectAtIndex:(NSUInteger)arc4random_uniform((int)self.subdivisions.count)];
        [self.rootView bringSubviewToFront:subDotView];
    }
    
    [self.rootView bringSubviewToFront:self];
}

- (CGRect)frameForRow:(int)row column:(int)column {
    CGFloat oddSizeBuffer = 0.0f;
    if (numberOfSubdivisions % 2 > 0) {
        oddSizeBuffer = 0.5f;
    }
    return CGRectMake(column * self.bounds.size.width / (float) numberOfSubdivisions + self.frame.origin.x,
                      row * self.bounds.size.height / (float) numberOfSubdivisions + self.frame.origin.y,
                      self.bounds.size.width / (float) numberOfSubdivisions + oddSizeBuffer,
                      self.bounds.size.height / (float) numberOfSubdivisions + oddSizeBuffer);
}

- (UITapGestureRecognizer *)tap {
    if (!_tap) {
        _tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                       action:@selector(tapped:)];
    }
    
    return _tap;
}

- (void)tapped:(UITapGestureRecognizer *)tap {
    self.isDivided = YES;
    [self layoutSubviews];
}

- (UISwipeGestureRecognizer *)swipe {
    if (!_swipe) {
        _swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                           action:@selector(swiped:)];
    }
    
    return _swipe;
}

- (void)swiped:(UISwipeGestureRecognizer *)swipe {
    self.isDivided = YES;
    [self layoutSubviews];
}

- (UIPanGestureRecognizer *)pan {
    if (!_pan) {
        _pan = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                       action:@selector(swiped:)];
    }
    
    return _pan;
}

- (void)panned:(UIPanGestureRecognizer *)pan {
    self.isDivided = YES;
    
    [self layoutSubviews];
}

- (void)dragged:(id)sender {
    if (self.isDivided) {
        return;
    }
    self.isDivided = YES;
    [self layoutSubviews];
}

- (void)removeSubdivisions {
    for (PDPDotView *dot in self.subdivisions) {
        [dot removeSubdivisions];
    }
    
    [self removeFromSuperview];
    [self.subdivisions removeAllObjects];
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchLocation = [touch locationInView:touch.view];
    NSLog(@"Inside Dot: %f - %f", touchLocation.x, touchLocation.y);
}
@end
