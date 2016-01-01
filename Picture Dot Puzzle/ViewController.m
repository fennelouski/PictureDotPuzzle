//
//  ViewController.m
//  Picture Dot Puzzle
//
//  Created by HAI on 12/16/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//

#import "ViewController.h"
#import "PDPDotView.h"
#import "PDPDataManager.h"
#import "PDPTouchInterceptView.h"
#import "UIImage+PixelInformation.h"
#import "UIImage+ImageEffects.h"
#import "NGAParallaxMotion.h"
#import "NKFToolbar.h"

#define degreesToRadians(x) (M_PI * (x) / 180.0)

static CGFloat const toolbarHeight = 44.0f;

@interface ViewController ()  <UIImagePickerControllerDelegate, UINavigationControllerDelegate, PDPTouchInterceptViewDelegate>

@property (nonatomic, strong) NSMutableArray *dots;

@property (nonatomic) NSInteger numberOfRows, numberOfColumns;

@property (nonatomic, strong) PDPTouchInterceptView *interceptView;

@property (nonatomic, strong) UIView *rootDotContainer;
@property (nonatomic, strong) PDPDotView *rootDot;

@property (nonatomic, strong) UIScreenEdgePanGestureRecognizer *screenEdgePanGestureRecognizer;
@property (nonatomic, strong) UISwipeGestureRecognizer *swipeDown, *swipeUp;
@property (nonatomic, strong) UITapGestureRecognizer *tap;


@property (nonatomic, strong) NKFToolbar *footerToolbar;
@property (nonatomic, strong) UIBarButtonItem *flexibleSpace;
@property (nonatomic, strong) UIBarButtonItem *shareButton, *hideButton, *automateButton, *pauseAutomateButton, *resetButton, *photoButton;

@property (nonatomic, strong) NKFToolbar *headerToolbar;
@property (nonatomic, strong) UISlider *cornerRadiusSlider;

@property (nonatomic, strong) UIImagePickerController *imagePicker;

@property (nonatomic, strong) UIImageView *backgroundImageView;

@end

@implementation ViewController {
    UIStatusBarStyle _preferredStatusBarStyle;
    BOOL _showToolBars;
    NSMutableArray *_recentTouchLocations;
    BOOL _automating;
    NSMutableDictionary *_sliderImages;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.view addSubview:self.backgroundImageView];
    [self.view addSubview:self.rootDotContainer];
    [self.view addSubview:self.headerToolbar];
    [self.view addSubview:self.footerToolbar];
    [self.view addGestureRecognizer:self.screenEdgePanGestureRecognizer];
    [self.view addGestureRecognizer:self.swipeUp];
    [self.view addGestureRecognizer:self.swipeDown];
    [self.view addGestureRecognizer:self.tap];
    
    _preferredStatusBarStyle = UIStatusBarStyleDefault;
    [self updateBackgroundColorWithImage:[PDPDataManager sharedDataManager].image];
    
    [self updateToolbars];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(animateUpdateViewConstraints)
                                                 name:UIApplicationWillChangeStatusBarFrameNotification
                                               object:nil];
    
    NSNotificationCenter *notificaitonCenter = [NSNotificationCenter defaultCenter];
    [notificaitonCenter addObserver:self
                           selector:@selector(updateViewConstraints)
                               name:UIDeviceOrientationDidChangeNotification
                             object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self updateViewConstraints];
    [self updateToolbars];
    
    [self animateUpdateViewConstraints];
}

- (void)animateUpdateViewConstraints {
    [UIView animateWithDuration:0.35f
                     animations:^{
                         [self updateViewConstraints];
                     }];
}

- (void)updateViewConstraints {
    [super updateViewConstraints];
    
    if ([UIApplication sharedApplication].statusBarFrame.size.height > 20.0f) {
        self.rootDotContainer.center = CGPointMake(self.view.frame.size.width * 0.5f,
                                                   self.view.frame.size.height * 0.5f - [UIApplication sharedApplication].statusBarFrame.size.height + 20.0f);
    } else {
        self.rootDotContainer.center = self.view.center;
    }
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    [self updateToolbars];
}


#pragma mark - Subviews

- (UIImageView *)backgroundImageView {
    if (!_backgroundImageView) {
        _backgroundImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        _backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
        _backgroundImageView.alpha = 0.5f; // allow the background view to be subtle
    }
    
    return _backgroundImageView;
}

- (PDPTouchInterceptView *)interceptView {
    if (!_interceptView) {
        _interceptView.delegate = self;
        _interceptView = [[PDPTouchInterceptView alloc] initWithFrame:self.rootDotContainer.bounds];
    }
    
    return _interceptView;
}

- (UIView *)rootDotContainer {
    if (!_rootDotContainer) {
        _rootDotContainer = [[UIView alloc] initWithFrame:CGRectMake(0.0f,
                                                                     0.0f,
                                                                     self.view.frame.size.width,
                                                                     self.view.frame.size.width)];
        _rootDotContainer.center = self.view.center;
        [_rootDotContainer addSubview:self.rootDot];
        [_rootDotContainer addSubview:self.interceptView];
        _rootDotContainer.parallaxIntensity = 10.0f;
        _rootDotContainer.parallaxDirectionConstraint = NGAParallaxDirectionConstraintVertical;
    }
    
    return _rootDotContainer;
}

- (PDPDotView *)rootDot {
    if (!_rootDot) {
        _rootDot = [[PDPDotView alloc] initWithFrame:self.rootDotContainer.bounds];
        
        if ([PDPDataManager sharedDataManager].canMutateAllDots) {
            [[PDPDataManager sharedDataManager].allDots addObject:_rootDot];
        } else {
            [[PDPDataManager sharedDataManager].reserveDots addObject:_rootDot];
            NSLog(@"Reserve count: %zd", [PDPDataManager sharedDataManager].reserveDots.count);
        }
        _rootDot.rootView = _rootDot;
    }
    
    return _rootDot;
}

- (NKFToolbar *)footerToolbar {
    if (!_footerToolbar) {
        _footerToolbar = [[NKFToolbar alloc] initWithFrame:CGRectMake(0.0f, self.view.frame.size.height, self.view.frame.size.width, toolbarHeight)];
        [_footerToolbar setItems:@[self.shareButton, self.flexibleSpace, self.automateButton, self.flexibleSpace, self.resetButton, self.flexibleSpace, self.photoButton]
                             animated:NO];
        _footerToolbar.usesSpaces = YES;
    }
    
    return _footerToolbar;
}

- (UIBarButtonItem *)flexibleSpace {
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                         target:self
                                                         action:nil];
}

- (UIBarButtonItem *)shareButton {
    if (!_shareButton) {
        _shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                     target:self
                                                                     action:@selector(shareButtonTouched:)];
    }
    
    return _shareButton;
}

- (UIBarButtonItem *)hideButton {
    if (!_hideButton) {
        _hideButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                    target:self
                                                                    action:@selector(hideButtonTouched:)];
    }
    
    return _hideButton;
}

- (UIBarButtonItem *)automateButton {
    if (!_automateButton) {
        _automateButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
                                                                        target:self
                                                                        action:@selector(automateButtonTouched:)];
    }
    
    return _automateButton;
}

- (UIBarButtonItem *)pauseAutomateButton {
    if (!_pauseAutomateButton) {
        _pauseAutomateButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause
                                                                             target:self
                                                                             action:@selector(automateButtonTouched:)];
    }
    
    return _pauseAutomateButton;
}

- (UIBarButtonItem *)resetButton {
    if (!_resetButton) {
        _resetButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Reset", nil)
                                                        style:UIBarButtonItemStyleDone
                                                       target:self
                                                       action:@selector(resetButtonTouched:)];
    }
    
    return _resetButton;
}

- (UIBarButtonItem *)photoButton {
    if (!_photoButton) {
        _photoButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                                                                     target:self
                                                                     action:@selector(photoButtonTouched:)];
    }
    
    return _photoButton;
}



- (NKFToolbar *)headerToolbar {
    if (!_headerToolbar) {
        _headerToolbar = [[NKFToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, toolbarHeight)];
        [_headerToolbar addSubview:self.cornerRadiusSlider];
    }
    
    return _headerToolbar;
}

- (UISlider *)cornerRadiusSlider {
    if (!_cornerRadiusSlider) {
        _cornerRadiusSlider = [[UISlider alloc] initWithFrame:CGRectInset(_headerToolbar.bounds, toolbarHeight, 10.0f)];
        _cornerRadiusSlider.minimumValue = 0.001f;
        _cornerRadiusSlider.maximumValue = 0.6f;
        _cornerRadiusSlider.value = [[PDPDataManager sharedDataManager] cornerRadius];
        _cornerRadiusSlider.minimumTrackTintColor = [UIColor grayColor];
        _cornerRadiusSlider.maximumTrackTintColor = [UIColor lightGrayColor];
        [_cornerRadiusSlider addTarget:self
                                action:@selector(sliderTouched:)
                      forControlEvents:UIControlEventAllEvents];
        [self sliderTouched:_cornerRadiusSlider];
        [_cornerRadiusSlider setMaximumTrackImage:[UIImage imageNamed:@"Maximum Track Image"]
                                         forState:UIControlStateNormal];
        [_cornerRadiusSlider setMinimumTrackImage:[UIImage imageNamed:@"Minimum Track Image"]
                                         forState:UIControlStateNormal];
    }
    
    return _cornerRadiusSlider;
}


#pragma mark - View Controllers

- (UIImagePickerController *)imagePicker {
    if (!_imagePicker) {
        _imagePicker = [[UIImagePickerController alloc] init];
        _imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        _imagePicker.delegate = self;
        _imagePicker.allowsEditing = YES;
        _imagePicker.navigationBarHidden = YES;
    }
    
    return _imagePicker;
}





#pragma mark - Button Actions

- (void)hideButtonTouched:(UIBarButtonItem *)hideButton {
    [self resignFirstResponder];
}

- (void)photoButtonTouched:(UIBarButtonItem *)photoButton {
    _automating = NO;
    [self updateFooterToolbarItems];
    [self presentViewController:self.imagePicker
                       animated:YES
                     completion:^{
                         
                     }];
}

- (void)resetButtonTouched:(UIBarButtonItem *)resetButton {
    _automating = NO;
    [self updateFooterToolbarItems];
    NSMutableArray *subviews = [[self.view subviews] mutableCopy];
    [subviews addObjectsFromArray:self.rootDotContainer.subviews];
    
    for (PDPDotView *dot in subviews) {
        [dot removeFromSuperview];
    }
    
    [[[PDPDataManager sharedDataManager] allDots] removeAllObjects];
    [PDPDataManager sharedDataManager].dotNumber = 0;
    
    [self.rootDot removeSubdivisions];
    self.rootDot = nil;
    [self.view addSubview:self.footerToolbar];
    [self.view addSubview:self.headerToolbar];
    [self.view addSubview:self.rootDotContainer];
    [self.rootDotContainer addSubview:self.rootDot];
    [self.rootDotContainer addSubview:self.interceptView];
    self.rootDot.isDivided = NO;
    [self.footerToolbar setItems:@[self.shareButton, self.flexibleSpace, self.automateButton, self.flexibleSpace, self.resetButton, self.flexibleSpace, self.photoButton] animated:YES];
    [self.rootDot layoutSubviews];
}

- (void)shareButtonTouched:(UIBarButtonItem *)shareButton {
    _automating = NO;
    [self updateFooterToolbarItems];
    self.rootDotContainer.backgroundColor = self.backgroundColor;
    UIImage *exportImage = [self imageFromView:self.rootDotContainer];
    self.rootDotContainer.backgroundColor = [UIColor clearColor];
    
    NSArray *activityItems = @[exportImage];
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItems
                                                                             applicationActivities:nil];
    activityVC.popoverPresentationController.barButtonItem = self.shareButton;
    [self presentViewController:activityVC
                       animated:YES
                     completion:nil];
}

- (void)sliderTouched:(UISlider *)slider {
    if ([slider isEqual:self.cornerRadiusSlider]) {
        [PDPDataManager sharedDataManager].cornerRadius = slider.value;
        if (slider.value > 0.45 && slider.value < 0.55f) {
            [PDPDataManager sharedDataManager].cornerRadius = 0.5f;
        }
        
        if (!_sliderImages) {
            _sliderImages = [NSMutableDictionary new];
        }
        
        if (![_sliderImages objectForKey:@([PDPDataManager sharedDataManager].cornerRadius)]) {
            UIView *sliderViewContainer = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, toolbarHeight, toolbarHeight)];
            UIView *sliderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, toolbarHeight * 0.7f, toolbarHeight * 0.7f)];
            sliderView.backgroundColor = [UIColor whiteColor];
            sliderView.layer.cornerRadius = sliderView.frame.size.height * slider.value;
            UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:sliderView.bounds];
            sliderView.layer.masksToBounds = NO;
            sliderView.layer.shadowColor = [UIColor blackColor].CGColor;
            CGFloat widthShadowOffset = (([PDPDataManager sharedDataManager].cornerRadius - slider.minimumValue)/(slider.maximumValue - slider.minimumValue)) * 4.0f - 2.0f;
            sliderView.center = CGPointMake(sliderViewContainer.frame.size.width * 0.5f - widthShadowOffset,
                                            sliderViewContainer.frame.size.height * 0.5f);
            sliderView.layer.shadowOffset = CGSizeMake(widthShadowOffset, 2.0f);
            sliderView.layer.shadowOpacity = 0.5f;
            sliderView.layer.shadowPath = shadowPath.CGPath;
            [sliderViewContainer addSubview:sliderView];
            UIImage *sliderImage = [self imageFromView:sliderViewContainer];
            if (sliderImage) {
                [_sliderImages setObject:sliderImage
                                  forKey:@([PDPDataManager sharedDataManager].cornerRadius)];
                [slider setThumbImage:sliderImage
                             forState:UIControlStateNormal];
            }
        } else {
            [slider setThumbImage:[_sliderImages objectForKey:@([PDPDataManager sharedDataManager].cornerRadius)]
                         forState:UIControlStateNormal];
        }
    }
}

- (void)automateButtonTouched:(UIBarButtonItem *)automateButton {
    if (!_automating) {
        [self beginAutomation];
    } else {
        _automating = !_automating;
    }
    
    [self updateFooterToolbarItems];
}

- (void)updateFooterToolbarItems {
    if ([PDPDataManager sharedDataManager].progress > 0.99f) {
        [self.footerToolbar setItems:@[self.shareButton,
                                       self.flexibleSpace,
                                       self.resetButton,
                                       self.flexibleSpace,
                                       self.photoButton]
                            animated:NO];
        [self.resetButton setEnabled:YES];
        [self.photoButton setEnabled:YES];
    } else {
        if (_automating) {
            [self.footerToolbar setItems:@[self.shareButton,
                                           self.flexibleSpace,
                                           self.pauseAutomateButton,
                                           self.flexibleSpace,
                                           self.resetButton,
                                           self.flexibleSpace,
                                           self.photoButton]
                                animated:YES];
            [self.resetButton setEnabled:NO];
            [self.photoButton setEnabled:NO];
        } else {
            [self.footerToolbar setItems:@[self.shareButton,
                                           self.flexibleSpace,
                                           self.automateButton,
                                           self.flexibleSpace,
                                           self.resetButton,
                                           self.flexibleSpace,
                                           self.photoButton]
                                animated:YES];
            [self.resetButton setEnabled:YES];
            [self.photoButton setEnabled:YES];
        }
    }
    self.pauseAutomateButton.tintColor = self.automateButton.tintColor;
}





#pragma mark - Gesture Recognizers

- (UIScreenEdgePanGestureRecognizer *)screenEdgePanGestureRecognizer {
    if (!_screenEdgePanGestureRecognizer) {
        _screenEdgePanGestureRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self
                                                                                            action:@selector(pannedFromEdge:)];
        _screenEdgePanGestureRecognizer.edges = UIRectEdgeBottom;
    }
    
    return _screenEdgePanGestureRecognizer;
}

- (UISwipeGestureRecognizer *)swipeDown {
    if (!_swipeDown) {
        _swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                               action:@selector(swiped:)];
        _swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    }
    
    return _swipeDown;
}

- (UISwipeGestureRecognizer *)swipeUp {
    if (!_swipeUp) {
        _swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                             action:@selector(swiped:)];
        _swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    }
    
    return _swipeUp;
}

- (UITapGestureRecognizer *)tap {
    if (!_tap) {
        _tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                       action:@selector(tapped:)];
        _tap.numberOfTapsRequired = 1;
    }
    
    return _tap;
}



#pragma mark - Gesture Recognizer Actions

- (void)pannedFromEdge:(UIScreenEdgePanGestureRecognizer *)pan {
    if (pan.state == UIGestureRecognizerStateBegan) {
        CGPoint p = [pan locationInView:self.view];
        
        [self checkForUpdateFromTouchPoint:p];
    }
}

- (void)swiped:(UISwipeGestureRecognizer *)swipe {
    if ([swipe isEqual:self.swipeUp] || [swipe isEqual:self.swipeDown]) {
        CGPoint p = [swipe locationInView:self.view];
        
        [self checkForUpdateFromTouchPoint:p];
    }
}

- (void)tapped:(UITapGestureRecognizer *)tap {
    if ([tap isEqual:self.tap]) {
        CGPoint p = [tap locationInView:self.view];
        
        [self checkForUpdateFromTouchPoint:p];
    }
}

- (void)checkForUpdateFromTouchPoint:(CGPoint)p {
    if (self.footerToolbar.orientation == NKFToolbarOrientationHorizontal) {
        CGFloat possibleTouchHeight = [self possibleTouchHeight];
        
        if (p.y > self.view.frame.size.height - possibleTouchHeight || p.y < possibleTouchHeight) {
            
            _showToolBars = !_showToolBars;
            
            [UIView animateWithDuration:[PDPDataManager sharedDataManager].animationDuration
                             animations:^{
                                 [self updateViewConstraints];
                                 [self updateToolbars];
                             }];
        }
    } else {
        CGFloat possibleTouchWidth = [self possibleTouchWidth];
        
        if (p.x > self.view.frame.size.width - possibleTouchWidth || p.x < possibleTouchWidth) {
            
            _showToolBars = !_showToolBars;
            
            [UIView animateWithDuration:[PDPDataManager sharedDataManager].animationDuration
                             animations:^{
                                 [self updateViewConstraints];
                                 [self updateToolbars];
                             }];
        }
    }
}

- (CGFloat)possibleTouchHeight {
    CGFloat possibleTouchHeight = (self.view.frame.size.height - self.view.frame.size.width) * 0.5f;

    if (possibleTouchHeight < toolbarHeight * 2.0f) {
        possibleTouchHeight = toolbarHeight * 2.0f;
    }
    
    return possibleTouchHeight;
}

- (CGFloat)possibleTouchWidth {
    CGFloat possibleTouchWidth = (self.view.frame.size.width - self.view.frame.size.height) * 0.5f;
    
    if (possibleTouchWidth < self.footerToolbar.frame.size.width * 2.0f) {
        possibleTouchWidth = self.footerToolbar.frame.size.width * 2.0f;
    }
    
    return possibleTouchWidth;
}

- (void)updateToolbars {
    if ([UIDevice currentDevice].orientation == UIDeviceOrientationPortrait) {
        CGAffineTransform rotateTransform = CGAffineTransformMakeRotation(degreesToRadians(0));
        self.cornerRadiusSlider.transform = rotateTransform;
        
        self.footerToolbar.orientation = NKFToolbarOrientationHorizontal;
        self.headerToolbar.orientation = NKFToolbarOrientationHorizontal;
        
        self.headerToolbar.frame = CGRectMake(0.0f,
                                              0.0f,
                                              self.view.frame.size.height,
                                              toolbarHeight);

        self.footerToolbar.frame = CGRectMake(0.0f,
                                              self.view.frame.size.height - 44.0f,
                                              self.view.frame.size.width,
                                              44.0f);
        
        if (_showToolBars) {
            [self.footerToolbar layoutSubviews];
            [self.headerToolbar layoutSubviews];
            
            self.headerToolbar.center = CGPointMake(self.view.frame.size.width * 0.5f,
                                                    self.headerToolbar.frame.size.height * 0.5f);
            self.footerToolbar.center = CGPointMake(self.view.frame.size.width * 0.5f,
                                                    self.view.frame.size.height - self.footerToolbar.frame.size.height * 0.5f);
        } else {
            self.headerToolbar.center = CGPointMake(self.view.frame.size.width * 0.5f,
                                                    self.headerToolbar.frame.size.height * -0.5f);
            self.footerToolbar.center = CGPointMake(self.view.frame.size.width * 0.5f,
                                                    self.view.frame.size.height + self.footerToolbar.frame.size.height * 0.5f);
        }
    } else if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
        CGAffineTransform rotateTransform = CGAffineTransformMakeRotation(degreesToRadians(90));
        self.cornerRadiusSlider.transform = rotateTransform;

        self.footerToolbar.orientation = NKFToolbarOrientationVertical;
        self.headerToolbar.orientation = NKFToolbarOrientationVertical;
        
        self.headerToolbar.frame = CGRectMake(0.0f,
                                              0.0f,
                                              toolbarHeight,
                                              self.view.frame.size.height);

        self.footerToolbar.frame = CGRectMake(0.0f,
                                              0.0f,
                                              60.0f,
                                              self.view.frame.size.height);
        
        if (_showToolBars) {
            self.headerToolbar.center = CGPointMake(self.view.frame.size.width - self.headerToolbar.frame.size.width * 0.5f,
                                                    self.view.frame.size.height * 0.5f);
            self.footerToolbar.center = CGPointMake(self.footerToolbar.frame.size.width * 0.5f,
                                                    self.view.frame.size.height * 0.5f);
            
            [self.footerToolbar layoutSubviews];
            [self.headerToolbar layoutSubviews];
        } else {
            self.headerToolbar.center = CGPointMake(self.view.frame.size.width + self.headerToolbar.frame.size.width * 0.5f,
                                                    self.view.frame.size.height * 0.5f);
            self.footerToolbar.center = CGPointMake(self.footerToolbar.frame.size.width * -0.5f,
                                                    self.view.frame.size.height * 0.5f);
        }
    }
    
    self.cornerRadiusSlider.center = CGPointMake(self.headerToolbar.frame.size.width * 0.5f,
                                                 self.headerToolbar.frame.size.height * 0.5f);
    
    [self.view addSubview:self.footerToolbar];
    [self.view addSubview:self.headerToolbar];
}



#pragma mark - Image Picker Delegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES
                               completion:^{
                                   
                               }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    
    [self updateBackgroundColorWithImage:image];
    self.backgroundImageView.image = [image applyBlurWithRadius:2.0f
                                                      tintColor:self.backgroundColor
                                          saturationDeltaFactor:0.2f
                                                      maskImage:image];
    
    [picker dismissViewControllerAnimated:YES
                               completion:^{
                                   
                               }];
}

- (void)updateBackgroundColorWithImage:(UIImage *)image {
    if (image) {
        [self resetButtonTouched:self.resetButton];
    }
    [[PDPDataManager sharedDataManager] setImage:image];
    NSLog(@"Image size width: %g\t\theight: %g", image.size.width, image.size.height);
    [self.rootDot layoutSubviews];
    
    self.backgroundColor = [[[PDPDataManager sharedDataManager] image] averageBorderColor];
    
    CGFloat red, green, blue, alpha;
    
    [self.backgroundColor getRed:&red
                           green:&green
                            blue:&blue
                           alpha:&alpha];
    
    self.footerToolbar.barTintColor = self.backgroundColor;
    self.headerToolbar.barTintColor = self.footerToolbar.barTintColor;
    self.view.backgroundColor = self.backgroundColor;
    
    CGFloat hue, saturation, brightness;
    [self.backgroundColor getHue:&hue
                      saturation:&saturation
                      brightness:&brightness
                           alpha:&alpha];
    
    if (brightness > 0.5f) {
        brightness *= 0.5f;
        saturation = 1.0f - saturation * 0.5f;
        _preferredStatusBarStyle = UIStatusBarStyleDefault;
        for (UIBarButtonItem *barButtonItem in self.footerToolbar.items) {
            barButtonItem.tintColor = [UIColor colorWithHue:hue
                                                 saturation:saturation
                                                 brightness:0.1f
                                                      alpha:1.0f];
        }
    } else {
        brightness = 1.0f - (1.0f - brightness) * 0.5f;
        saturation = 1.0f - saturation;
        _preferredStatusBarStyle = UIStatusBarStyleLightContent;
        for (UIBarButtonItem *barButtonItem in self.footerToolbar.items) {
            barButtonItem.tintColor = [UIColor colorWithHue:hue
                                                 saturation:0.1f
                                                 brightness:1.0f
                                                      alpha:1.0f];
        }
    }
    
    self.backgroundColor = [UIColor colorWithHue:hue
                                      saturation:saturation
                                      brightness:brightness
                                           alpha:alpha];
    
    self.accentColor1 = [UIColor colorWithHue:1.0f - red
                                   saturation:1.0f - green
                                   brightness:1.0f - blue
                                        alpha:1.0f];
    
    [self.accentColor1 getHue:&hue
                   saturation:&saturation
                   brightness:&brightness
                        alpha:&alpha];
    
    if (brightness < 0.5f) {
        brightness = brightness * 0.5f;
        saturation *= 2.5f;
    } else {
        brightness = 1.0f;
        saturation *= 0.5f;
    }
    
    saturation *= 0.2f;
    
    self.accentColor1 = [UIColor colorWithHue:hue
                                   saturation:saturation * 0.5f
                                   brightness:brightness
                                        alpha:1.0f];
    
    [self updateViewConstraints];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self setNeedsStatusBarAppearanceUpdate];
    });
}


#pragma mark - Navigation Controller Delegate



#pragma mark - Status Bar

- (UIStatusBarStyle)preferredStatusBarStyle {
    return _preferredStatusBarStyle;
}

- (BOOL)prefersStatusBarHidden {
    if (self.footerToolbar.orientation == NKFToolbarOrientationVertical) {
        return YES;
    }
    
    return _showToolBars;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationSlide;
}


#pragma mark - Automation

- (void)beginAutomation {
    if (_automating) {
        return;
    } else {
        _automating = YES;
    }
    
    if (!_recentTouchLocations) {
        _recentTouchLocations = [NSMutableArray new];
    } else {
        [_recentTouchLocations removeAllObjects];
    }
    
    NSTimeInterval duration = [PDPDataManager sharedDataManager].automationDuration;
    
    
    for (NSTimeInterval t = [PDPDataManager sharedDataManager].animationDuration, timeAddition = [PDPDataManager sharedDataManager].animationDuration; t < duration; t += timeAddition) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(t * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self touchAtRandom];
        });
        
        if (timeAddition > 0.05f) {
            timeAddition -= 0.05f;
            
            if ([PDPDataManager sharedDataManager].progress > 0.3f) {
                timeAddition = 0.01f;
            }
        }
        
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self finishTouches];
    });
}

- (void)touchAtRandom {
    if (!_automating) {
        return;
    }
    
    if (_recentTouchLocations.count > 16) {
        [_recentTouchLocations removeObjectAtIndex:0];
    }
    
    CGPoint randomPoint = CGPointMake(arc4random_uniform(self.rootDotContainer.frame.size.width),
                                      arc4random_uniform(self.rootDotContainer.frame.size.height));
    NSValue *dotPosition = [NSValue valueWithCGPoint:randomPoint];
    [_recentTouchLocations addObject:dotPosition];
    [self checkForDotsAtPoint:randomPoint];
}

- (void)finishTouches {
    if (!_automating) {
        return;
    }
    
    NSTimeInterval t = [PDPDataManager sharedDataManager].animationDuration;
    
    BOOL didFindUndividedDot = NO;
    
    [PDPDataManager sharedDataManager].canMutateAllDots = NO;
    NSArray *copiedAllDots = [NSArray arrayWithArray:[PDPDataManager sharedDataManager].allDots.allObjects];
    for (PDPDotView *dot in [PDPDataManager sharedDataManager].reserveDots) {
        [[PDPDataManager sharedDataManager].allDots addObject:dot];
    }
    [[PDPDataManager sharedDataManager].reserveDots removeAllObjects];
    [PDPDataManager sharedDataManager].canMutateAllDots = YES;
    
    NSArray *allDots = [copiedAllDots sortedArrayUsingComparator:^NSComparisonResult(PDPDotView *obj1, PDPDotView *obj2) {
        return obj1.divisionLevel > obj2.divisionLevel;
    }];
    
    float groupSize = exp2f([PDPDataManager sharedDataManager].maximumDivisionLevel);
    
    for (float i = 0; i < allDots.count && i < groupSize; i++) {
        PDPDotView *dot = [allDots objectAtIndex:i];
        
        if (!dot.isDivided) {
            dot.isDivided = YES;
            
            NSTimeInterval delay = (t / groupSize * i * t * i) * 0.025f;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [dot layoutSubviewsOnMainThread];
            });
            
            didFindUndividedDot = YES;
        }
    }
    
    if ([PDPDataManager sharedDataManager].dotNumber < [PDPDataManager sharedDataManager].totalNumberOfDotsPossible) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(t * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self touchAtRandom];
            [self finishTouches];
            self.pauseAutomateButton.enabled = NO;
            self.shareButton.enabled = NO;
            self.cornerRadiusSlider.enabled = NO;
        });
    } else {
        _automating = NO;
        
        NSTimeInterval waitTime = 0.25f;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(waitTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self updateFooterToolbarItems];
            self.pauseAutomateButton.enabled = YES;
            self.shareButton.enabled = YES;
            self.cornerRadiusSlider.enabled = YES;
        });
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(waitTime * NSEC_PER_SEC)), dispatch_queue_create(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self replaceDotsWithImage];
        });
    }
}

- (void)replaceDotsWithImage {
    UIImage *completedImage = [self imageFromView:self.rootDotContainer];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        for (PDPDotView *dot in [PDPDataManager sharedDataManager].allDots) {
            [dot removeFromSuperview];
        }
        
        UIImageView *completedImageView = [[UIImageView alloc] initWithImage:completedImage];
        completedImageView.frame = self.rootDotContainer.bounds;
        
        [self.rootDotContainer addSubview:completedImageView];
        
        [self.rootDot removeSubdivisions];
    });
}

#pragma mark - Measuring Touches

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchLocation = [touch locationInView:touch.view];
    
    if (CGRectContainsPoint(self.rootDotContainer.frame, [touch locationInView:self.view])) {
        [self checkForDotsAtPoint:touchLocation];
        
        if (_showToolBars) {
            _showToolBars = NO;
            [UIView animateWithDuration:[PDPDataManager sharedDataManager].animationDuration
                             animations:^{
                                 [self updateToolbars];
                                 [self setNeedsStatusBarAppearanceUpdate];
                             }];
        }
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchLocation = [touch locationInView:touch.view];
    
    if (CGRectContainsPoint(self.rootDotContainer.frame, [touch locationInView:self.view])) {
        [self checkForDotsAtPoint:touchLocation];
    }
}

- (void)checkForDotsAtPoint:(CGPoint)point {
    NSArray *allDots = [[[PDPDataManager sharedDataManager] allDots] allObjects];
    for (PDPDotView *dot in allDots) {
        if (CGRectContainsPoint(dot.frame, point)) {
            if ([dot respondsToSelector:@selector(isDivided)] && !dot.isDivided) {
                dot.isDivided = YES;
                [dot layoutSubviews];
                return;
            }
        }
    }
}


#pragma mark - Image Conversion
// this should be added as a category on UIView

- (UIImage *)imageFromView:(UIView *) view {
    CGFloat scale = [UIScreen mainScreen].scale;
    
    if (view.bounds.size.width + view.bounds.size.height > 1200) {
        scale *= 2;
    }
    
    if (scale > 1) {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, scale);
    } else {
        UIGraphicsBeginImageContext(view.bounds.size);
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    [view.layer renderInContext: context];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return viewImage;
}



#pragma mark - Memory Warning

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
