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
#import <PhotosUI/PhotosUI.h>

#define degreesToRadians(x) (M_PI * (x) / 180.0)

static CGFloat const toolbarHeight = 44.0f;

@interface ViewController ()  <PHPickerViewControllerDelegate, PDPTouchInterceptViewDelegate>

@property (nonatomic, strong) NSMutableArray *dots;

@property (nonatomic) NSInteger numberOfRows, numberOfColumns;

@property (nonatomic, strong) PDPTouchInterceptView *interceptView;

@property (nonatomic, strong) UIView *rootDotContainer;
@property (nonatomic, strong) PDPDotView *rootDot;

@property (nonatomic, strong) UIScreenEdgePanGestureRecognizer *screenEdgePanGestureRecognizer;
@property (nonatomic, strong) UISwipeGestureRecognizer *swipeDown, *swipeUp, *swipeLeft, *swipeRight;
@property (nonatomic, strong) UITapGestureRecognizer *tap;


@property (nonatomic, strong) NKFToolbar *footerToolbar;
@property (nonatomic, strong) UIBarButtonItem *flexibleSpace;
@property (nonatomic, strong) UIBarButtonItem *shareButton, *hideButton, *automateButton, *pauseAutomateButton, *resetButton, *photoButton;

@property (nonatomic, strong) NKFToolbar *headerToolbar;
@property (nonatomic, strong) UISlider *cornerRadiusSlider;

@property (nonatomic, strong) PHPickerViewController *imagePicker;

@property (nonatomic, strong) UIImageView *backgroundImageView;

@property (nonatomic, strong) UIImageView *originalImageView;

@property (nonatomic, strong) CADisplayLink *displayLink;

@end

@implementation ViewController {
    CGSize lastFrameSize;
    UIStatusBarStyle _preferredStatusBarStyle;
    BOOL _showToolBars;
    NSMutableArray *_recentTouchLocations;
    BOOL _automating;
    NSMutableDictionary *_sliderImages;
    BOOL _imagePickerPresented;
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
    [self.view addGestureRecognizer:self.swipeLeft];
    [self.view addGestureRecognizer:self.swipeRight];
    [self.view addGestureRecognizer:self.tap];

    if (@available(iOS 13.0, *)) {
        _preferredStatusBarStyle = UIStatusBarStyleDarkContent;
    } else {
        _preferredStatusBarStyle = UIStatusBarStyleDefault;
    }
    [self updateBackgroundColorWithImage:[PDPDataManager sharedDataManager].image];
    
    [self updateToolbars];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateViewConstraints)
                                                 name:UIApplicationWillChangeStatusBarFrameNotification
                                               object:nil];
    
    // Use CADisplayLink for smooth updates instead of NSTimer
    // Set to 30 FPS for smooth animations while being battery-efficient
    // On ProMotion displays (iPhone 13 Pro+), this allows adaptive refresh
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateLoop)];
    self.displayLink.preferredFramesPerSecond = 30; // 30 FPS - smooth on all devices including ProMotion
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self updateViewConstraints];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    // Handle orientation changes and layout updates using modern API
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self updateViewConstraints];
    } completion:nil];
}

- (void)updateLoop {
    if ((lastFrameSize.width != self.view.bounds.size.width || lastFrameSize.height != self.view.bounds.size.height)
        || (![self.headerToolbar.superview isEqual:self.view] || ![self.footerToolbar.superview isEqual:self.view])) {
        
        self.rootDotContainer.frame = CGRectMake(0.0f,
                                                 0.0f,
                                                 self.view.bounds.size.width < self.view.bounds.size.height ? self.view.bounds.size.width : self.view.bounds.size.height,
                                                 self.view.bounds.size.width < self.view.bounds.size.height ? self.view.bounds.size.width : self.view.bounds.size.height);
        self.rootDot.frame = self.rootDotContainer.bounds;
        [self.rootDot layoutSubviews];
        
        [self updateViewConstraints];
        [self updateToolbars];
        [self performSelector:@selector(updateToolbars)
                   withObject:self
                   afterDelay:2.35f];
        lastFrameSize = self.view.bounds.size;
    }
    
    CGFloat progress = [PDPDataManager sharedDataManager].progress;
    progress *= progress * progress * progress;
    self.originalImageView.alpha = progress;
    self.originalImageView.layer.cornerRadius = (1.0f - progress) * self.originalImageView.frame.size.width;
}

- (void)updateViewConstraints {
    [super updateViewConstraints];
    
    if (_imagePickerPresented) {
        return;
    }
    
    // Use Safe Area insets for modern iOS devices (notch, Dynamic Island)
    CGFloat topInset = 0.0f;
    if (@available(iOS 11.0, *)) {
        topInset = self.view.safeAreaInsets.top;
    }

    if (topInset > 20.0f) {
        // Adjust for devices with notch or Dynamic Island
        CGFloat offset = (topInset - 20.0f) * 0.5f;
        self.rootDotContainer.center = CGPointMake(self.view.frame.size.width * 0.5f,
                                                   self.view.frame.size.height * 0.5f - offset);
    } else {
        self.rootDotContainer.center = self.view.center;
    }
    
    self.originalImageView.frame = self.rootDotContainer.bounds;
    
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
                                                                     self.view.frame.size.width < self.view.frame.size.height ? self.view.frame.size.width : self.view.frame.size.height,
                                                                     self.view.frame.size.width < self.view.frame.size.height ? self.view.frame.size.width : self.view.frame.size.height)];
        _rootDotContainer.center = self.view.center;
        [_rootDotContainer addSubview:self.rootDot];
        [_rootDotContainer addSubview:self.interceptView];
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
        _rootDot.relativeCenter = CGPointMake(0.5f,
                                              0.5f);
    }
    
    return _rootDot;
}

- (NKFToolbar *)footerToolbar {
    if (!_footerToolbar) {
        _footerToolbar = [[NKFToolbar alloc] initWithFrame:CGRectMake(0.0f, self.view.frame.size.height, self.view.frame.size.width, toolbarHeight)];
        [_footerToolbar setItems:@[self.shareButton, self.flexibleSpace, self.automateButton, self.flexibleSpace, self.resetButton, self.flexibleSpace, self.photoButton]
                             animated:NO];
        _footerToolbar.usesSpaces = YES;
        _footerToolbar.orientation = YES;
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
        _shareButton.accessibilityLabel = @"Share";
        _shareButton.accessibilityHint = @"Share the puzzle image";
    }

    return _shareButton;
}

- (UIBarButtonItem *)hideButton {
    if (!_hideButton) {
        _hideButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                    target:self
                                                                    action:@selector(hideButtonTouched:)];
        _hideButton.accessibilityLabel = @"Hide";
        _hideButton.accessibilityHint = @"Hide toolbars";
    }

    return _hideButton;
}

- (UIBarButtonItem *)automateButton {
    if (!_automateButton) {
        _automateButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
                                                                        target:self
                                                                        action:@selector(automateButtonTouched:)];
        _automateButton.accessibilityLabel = @"Automate";
        _automateButton.accessibilityHint = @"Automatically create puzzle dots";
    }

    return _automateButton;
}

- (UIBarButtonItem *)pauseAutomateButton {
    if (!_pauseAutomateButton) {
        _pauseAutomateButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause
                                                                             target:self
                                                                             action:@selector(automateButtonTouched:)];
        _pauseAutomateButton.accessibilityLabel = @"Pause";
        _pauseAutomateButton.accessibilityHint = @"Pause automatic puzzle creation";
    }

    return _pauseAutomateButton;
}

- (UIBarButtonItem *)resetButton {
    if (!_resetButton) {
        _resetButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Reset", nil)
                                                        style:UIBarButtonItemStyleDone
                                                       target:self
                                                       action:@selector(resetButtonTouched:)];
        _resetButton.accessibilityLabel = @"Reset";
        _resetButton.accessibilityHint = @"Clear puzzle and start over";
    }

    return _resetButton;
}

- (UIBarButtonItem *)photoButton {
    if (!_photoButton) {
        _photoButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                                                                     target:self
                                                                     action:@selector(photoButtonTouched:)];
        _photoButton.accessibilityLabel = @"Choose Photo";
        _photoButton.accessibilityHint = @"Select a photo to create a puzzle";
    }

    return _photoButton;
}



- (NKFToolbar *)headerToolbar {
    if (!_headerToolbar) {
        _headerToolbar = [[NKFToolbar alloc] initWithFrame:CGRectMake(0.0f,
                                                                      0.0f,
                                                                      self.view.frame.size.width,
                                                                      toolbarHeight)];
        [_headerToolbar addSubview:self.cornerRadiusSlider];
    }
    
    return _headerToolbar;
}

- (UISlider *)cornerRadiusSlider {
    if (!_cornerRadiusSlider) {
        _cornerRadiusSlider = [[UISlider alloc] initWithFrame:CGRectInset(_headerToolbar.bounds, toolbarHeight, 10.0f)];
        _cornerRadiusSlider.minimumValue = 0.001f;
        _cornerRadiusSlider.maximumValue = 0.6f;
        _cornerRadiusSlider.value = [PDPDataManager sharedDataManager].cornerRadius;
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
        _cornerRadiusSlider.accessibilityLabel = @"Corner Radius";
        _cornerRadiusSlider.accessibilityHint = @"Adjust the roundness of puzzle dots";
    }

    return _cornerRadiusSlider;
}

- (UIImageView *)originalImageView {
    if (!_originalImageView) {
        _originalImageView = [[UIImageView alloc] initWithImage:[PDPDataManager sharedDataManager].image];
        _originalImageView.contentMode = UIViewContentModeScaleAspectFill;
        _originalImageView.frame = self.rootDotContainer.frame;
        _originalImageView.clipsToBounds = YES;
        _originalImageView.layer.cornerRadius = [PDPDataManager sharedDataManager].cornerRadius;
    }
    
    return _originalImageView;
}


#pragma mark - View Controllers

- (PHPickerViewController *)imagePicker {
    if (!_imagePicker) {
        PHPickerConfiguration *config = [[PHPickerConfiguration alloc] init];
        config.selectionLimit = 1;
        config.filter = [PHPickerFilter imagesFilter];

        _imagePicker = [[PHPickerViewController alloc] initWithConfiguration:config];
        _imagePicker.delegate = self;
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
    _imagePickerPresented = YES;
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
//    [self.rootDotContainer addSubview:self.originalImageView];
    [self.rootDotContainer addSubview:self.rootDot];
    [self.rootDotContainer addSubview:self.interceptView];
    self.rootDot.isDivided = NO;
    [self.footerToolbar setItems:@[self.shareButton, self.flexibleSpace, self.automateButton, self.flexibleSpace, self.resetButton, self.flexibleSpace, self.photoButton] animated:YES];
    [self.rootDot layoutSubviews];
}

- (void)shareButtonTouched:(UIBarButtonItem *)shareButton {
    _automating = NO;
    [self updateFooterToolbarItems];
    self.rootDotContainer.backgroundColor = self.accentColor2;
    [self.rootDotContainer addSubview:self.originalImageView];
    [self.rootDotContainer sendSubviewToBack:self.originalImageView];
    UIImage *exportImage = [self imageFromView:self.rootDotContainer];
    [self.originalImageView removeFromSuperview];
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
                            animated:YES];
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

- (UISwipeGestureRecognizer *)swipeLeft {
    if (!_swipeLeft) {
        _swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                               action:@selector(swiped:)];
        _swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    }
    
    return _swipeLeft;
}

- (UISwipeGestureRecognizer *)swipeRight {
    if (!_swipeRight) {
        _swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                action:@selector(swiped:)];
        _swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    }
    
    return _swipeRight;
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
    if ((([swipe isEqual:self.swipeUp] || [swipe isEqual:self.swipeDown]) && self.view.frame.size.height > self.view.frame.size.width)
        || (([swipe isEqual:self.swipeLeft] || [swipe isEqual:self.swipeRight]) && self.view.frame.size.width > self.view.frame.size.height)){
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
    BOOL shouldUpdate = NO;
    
    if (self.footerToolbar.orientation == NKFToolbarOrientationHorizontal) {
        CGFloat possibleTouchHeight = [self possibleTouchHeight];
        
        if (p.y > self.view.frame.size.height - possibleTouchHeight || p.y < possibleTouchHeight) {
            
            _showToolBars = !_showToolBars;
            
            shouldUpdate = YES;
        }
    } else {
        CGFloat possibleTouchWidth = [self possibleTouchWidth];
        
        if (p.x > self.view.frame.size.width - possibleTouchWidth || p.x < possibleTouchWidth) {
            
            _showToolBars = !_showToolBars;
            
            shouldUpdate = YES;
        }
    }
    
    if (shouldUpdate) {
        [UIView animateWithDuration:[PDPDataManager sharedDataManager].animationDuration
                         animations:^{
                             [self updateViewConstraints];
                         }];
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
    [self setNeedsStatusBarAppearanceUpdate];
    
    if (self.view.frame.size.height > self.view.frame.size.width) { // toolbars are horizontal
        CGAffineTransform rotateTransform = CGAffineTransformMakeRotation(degreesToRadians(0));
        self.cornerRadiusSlider.transform = rotateTransform;
        self.cornerRadiusSlider.frame = CGRectInset(_headerToolbar.bounds, toolbarHeight, 10.0f);
        
        self.footerToolbar.orientation = NKFToolbarOrientationHorizontal;
        self.headerToolbar.orientation = NKFToolbarOrientationHorizontal;
        
        self.headerToolbar.frame = CGRectMake(0.0f,
                                              0.0f,
                                              self.view.frame.size.width,
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
    } else { // toolbars are vertical
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
        
        self.cornerRadiusSlider.frame = CGRectInset(_headerToolbar.bounds, 10.0f, toolbarHeight);
    }
    
    self.cornerRadiusSlider.center = CGPointMake(self.headerToolbar.frame.size.width * 0.5f,
                                                 self.headerToolbar.frame.size.height * 0.5f);
    
    [self.view addSubview:self.footerToolbar];
    [self.view addSubview:self.headerToolbar];
    self.footerToolbar.barTintColor = self.accentColor2;
    self.headerToolbar.barTintColor = self.accentColor2;
}



#pragma mark - PHPicker Delegate

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:^{
        self->_imagePickerPresented = NO;
    }];

    if (results.count == 0) {
        [self.originalImageView removeFromSuperview];
        return;
    }

    PHPickerResult *result = results.firstObject;
    [result.itemProvider loadObjectOfClass:[UIImage class] completionHandler:^(__kindof id<NSItemProviderReading> _Nullable object, NSError * _Nullable error) {
        if ([object isKindOfClass:[UIImage class]]) {
            UIImage *image = (UIImage *)object;

            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"Original Image Size: %g, %g", image.size.width, image.size.height);

                [self updateBackgroundColorWithImage:image];
                self.backgroundImageView.image = [image applyBlurWithRadius:2.0f
                                                                  tintColor:self.backgroundColor
                                                      saturationDeltaFactor:0.2f
                                                                  maskImage:image];
                self.originalImageView.image = image;
            });
        }
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
        if (@available(iOS 13.0, *)) {
            _preferredStatusBarStyle = UIStatusBarStyleDarkContent;
        } else {
            _preferredStatusBarStyle = UIStatusBarStyleDefault;
        }
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
    
    self.accentColor2 = [UIColor colorWithHue:hue
                                   saturation:saturation * 0.5f
                                   brightness:(brightness > 0.5f) ? 0.1f : 0.9f
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
            
            NSTimeInterval delay = (t / groupSize * i * t * i) * 0.2f;
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

    UIGraphicsImageRendererFormat *format = [[UIGraphicsImageRendererFormat alloc] init];
    format.scale = scale;
    format.opaque = NO;

    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:view.bounds.size format:format];

    UIImage *viewImage = [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull rendererContext) {
        [view.layer renderInContext:rendererContext.CGContext];
    }];

    return viewImage;
}



#pragma mark - Auto rotate

- (BOOL)shouldAutorotate {
    return !_automating;
}


#pragma mark - Memory Warning

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [self.displayLink invalidate];
    self.displayLink = nil;
}

@end
