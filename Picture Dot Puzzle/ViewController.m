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


@property (nonatomic, strong) UIToolbar *footerToolbar;
@property (nonatomic, strong) UIBarButtonItem *flexibleSpace;
@property (nonatomic, strong) UIBarButtonItem *shareButton, *hideButton, *automateButton, *pauseAutomateButton, *resetButton, *photoButton;

@property (nonatomic, strong) UIToolbar *headerToolbar;
@property (nonatomic, strong) UISlider *cornerRadiusSlider;

@property (nonatomic, strong) UIImagePickerController *imagePicker;

@property (nonatomic, strong) UIImageView *backgroundImageView;

@end

@implementation ViewController {
    UIStatusBarStyle _preferredStatusBarStyle;
    BOOL _showToolBars;
    NSMutableArray *_recentTouchLocations;
    BOOL _automating;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    if (self.view.frame.size.width > 500.0f) {
        [PDPDataManager sharedDataManager].maximumDivisionLevel = 8;
    } else if (self.view.frame.size.width > 400.0f) {
        [PDPDataManager sharedDataManager].maximumDivisionLevel = 7;
    } else if (self.view.frame.size.width > 300.0f) {
        [PDPDataManager sharedDataManager].maximumDivisionLevel = 6;
    } else {
        [PDPDataManager sharedDataManager].maximumDivisionLevel = 5;
    }
    
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
    
//    NSTimer *submitTimer = [NSTimer scheduledTimerWithTimeInterval:2
//                                                            target:self
//                                                          selector:@selector(updateToolbars)
//                                                          userInfo:nil
//                                                           repeats:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self updateToolbars];
    [self updateViewConstraints];
    
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
    }
    
    return _rootDotContainer;
}

- (PDPDotView *)rootDot {
    if (!_rootDot) {
        _rootDot = [[PDPDotView alloc] initWithFrame:self.rootDotContainer.bounds];
        [[[PDPDataManager sharedDataManager] allDots] addObject:_rootDot];
        _rootDot.rootView = _rootDot;
        _rootDot.parallaxIntensity = 10.0f;
        _rootDot.parallaxDirectionConstraint = NGAParallaxDirectionConstraintVertical;
    }
    
    return _rootDot;
}

- (UIToolbar *)footerToolbar {
    if (!_footerToolbar) {
        _footerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, self.view.frame.size.height, self.view.frame.size.width, toolbarHeight)];
        [_footerToolbar setItems:@[self.shareButton, self.flexibleSpace, self.automateButton, self.flexibleSpace, self.resetButton, self.flexibleSpace, self.photoButton]
                             animated:NO];
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



- (UIToolbar *)headerToolbar {
    if (!_headerToolbar) {
        _headerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, toolbarHeight)];
        [_headerToolbar addSubview:self.cornerRadiusSlider];
    }
    
    return _headerToolbar;
}

- (UISlider *)cornerRadiusSlider {
    if (!_cornerRadiusSlider) {
        _cornerRadiusSlider = [[UISlider alloc] initWithFrame:CGRectInset(_headerToolbar.bounds, toolbarHeight, 10.0f)];
        _cornerRadiusSlider.minimumValue = 0.001f;
        _cornerRadiusSlider.maximumValue = 1.0f;
        _cornerRadiusSlider.value = [[PDPDataManager sharedDataManager] cornerRadius];
        _cornerRadiusSlider.minimumTrackTintColor = [UIColor grayColor];
        _cornerRadiusSlider.maximumTrackTintColor = [UIColor lightGrayColor];
        [_cornerRadiusSlider addTarget:self
                                action:@selector(sliderTouched:)
                      forControlEvents:UIControlEventAllEvents];
        
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
    
    [self.rootDot removeSubdivisions];
    self.rootDot = nil;
    [self.view addSubview:self.footerToolbar];
    [self.view addSubview:self.headerToolbar];
    [self.view addSubview:self.rootDotContainer];
    [self.rootDotContainer addSubview:self.rootDot];
    [self.rootDotContainer addSubview:self.interceptView];
    self.rootDot.isDivided = NO;
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
    }
}

- (void)automateButtonTouched:(UIBarButtonItem *)automateButton {
    if (!_automating) {
        [self beginAutomation];
    } else {
        _automating = !_automating;
        [automateButton setImage:(_automating ? [PDPDataManager sharedDataManager].image : [PDPDataManager sharedDataManager].image)];
    }
    
    [self updateFooterToolbarItems];
}

- (void)updateFooterToolbarItems {
    if (!_automating) {
        [self.footerToolbar setItems:@[self.shareButton, self.flexibleSpace, self.automateButton, self.flexibleSpace, self.resetButton, self.flexibleSpace, self.photoButton]
                            animated:YES];
    } else {
        [self.footerToolbar setItems:@[self.shareButton, self.flexibleSpace, self.pauseAutomateButton, self.flexibleSpace, self.resetButton, self.flexibleSpace, self.photoButton]
                            animated:YES];
        self.pauseAutomateButton.tintColor = self.automateButton.tintColor;
    }
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
        _tap.numberOfTapsRequired = 2;
    }
    
    return _tap;
}



#pragma mark - Gesture Recognizer Actions

- (void)pannedFromEdge:(UIScreenEdgePanGestureRecognizer *)pan {
    NSLog(@"Edge Panned!");
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
    CGFloat possibleTouchHeight = [self possibleTouchHeight];
    if (p.y > self.view.frame.size.height - possibleTouchHeight || p.y < possibleTouchHeight) {
        
        _showToolBars = !_showToolBars;
        
        if (_showToolBars) {
            NSLog(@"Show toolbars!");
        }
        
        [UIView animateWithDuration:[PDPDataManager sharedDataManager].animationDuration
                         animations:^{
                             [self updateViewConstraints];
                             [self updateToolbars];
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

- (void)updateToolbars {
    if (_showToolBars) {
        self.headerToolbar.center = CGPointMake(self.headerToolbar.center.x, fabs(self.headerToolbar.center.y));
        self.footerToolbar.center = CGPointMake(self.view.frame.size.width * 0.5f, self.view.frame.size.height - self.footerToolbar.frame.size.height * 0.5f);
    } else {
        self.headerToolbar.center = CGPointMake(self.headerToolbar.center.x, -fabs(self.headerToolbar.center.y));
        self.footerToolbar.center = CGPointMake(self.view.frame.size.width * 0.5f, self.view.frame.size.height + self.footerToolbar.frame.size.height * 0.5f);
    }
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
    [[PDPDataManager sharedDataManager] setImage:image];
    
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
        brightness = 1.0f - (1.0f - brightness) * 0.5f;
        _preferredStatusBarStyle = UIStatusBarStyleDefault;
    } else {
        brightness *= 0.5f;
        _preferredStatusBarStyle = UIStatusBarStyleLightContent;
    }
    
    self.backgroundColor = [UIColor colorWithHue:hue
                                      saturation:saturation
                                      brightness:brightness
                                           alpha:alpha];
    
    [self updateViewConstraints];
    
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

    for (UIBarButtonItem *barButtonItem in self.footerToolbar.items) {
        barButtonItem.tintColor = self.accentColor1;
    }
}


#pragma mark - Navigation Controller Delegate



#pragma mark - Status Bar

- (UIStatusBarStyle)preferredStatusBarStyle {
    return _preferredStatusBarStyle;
}

- (BOOL)prefersStatusBarHidden {
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
        [self performSelector:@selector(touchAtRandom)
                   withObject:nil
                   afterDelay:t];
        
        if (timeAddition > 0.05f) {
            timeAddition -= 0.05f;
        }
    }
    
    [self performSelector:@selector(finishTouches)
               withObject:nil
               afterDelay:duration];
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
    
    NSArray *allDots = [[[[PDPDataManager sharedDataManager] allDots] allObjects] sortedArrayUsingComparator:^NSComparisonResult(PDPDotView *obj1, PDPDotView *obj2) {
        return obj1.divisionLevel > obj2.divisionLevel;
    }];
    
    float groupSize = 16;
    
    for (float i = 0; i < allDots.count && i < groupSize; i++) {
        PDPDotView *dot = [allDots objectAtIndex:i];
        
        if (!dot.isDivided) {
            dot.isDivided = YES;
            [dot layoutSubviews];
            
            [dot performSelector:@selector(layoutSubviews)
                      withObject:nil
                      afterDelay:(t/groupSize) * i];
            didFindUndividedDot = YES;
        }
    }
    
    if (didFindUndividedDot) {
        [self performSelector:@selector(finishTouches)
                   withObject:nil
                   afterDelay:t];
    } else {
        _automating = NO;
        [self updateFooterToolbarItems];
    }
}

#pragma mark - Measuring Touches

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchLocation = [touch locationInView:touch.view];
    
    [self checkForDotsAtPoint:touchLocation];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchLocation = [touch locationInView:touch.view];
    
    [self checkForDotsAtPoint:touchLocation];
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
    CGFloat scale = [self screenScale];
    
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

- (float)screenScale {
    if ([ [UIScreen mainScreen] respondsToSelector: @selector(scale)] == YES) {
        return [ [UIScreen mainScreen] scale];
    }
    return 1;
}



#pragma mark - Memory Warning

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
