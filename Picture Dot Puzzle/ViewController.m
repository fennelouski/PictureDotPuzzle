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

@interface ViewController ()  <UIImagePickerControllerDelegate, UINavigationControllerDelegate, PDPTouchInterceptViewDelegate>

@property (nonatomic, strong) NSMutableArray *dots;

@property (nonatomic) NSInteger numberOfRows, numberOfColumns;

@property (nonatomic, strong) PDPTouchInterceptView *interceptView;

@property (nonatomic, strong) UIView *rootDotContainer;
@property (nonatomic, strong) PDPDotView *rootDot;

@property (nonatomic, strong) UIScreenEdgePanGestureRecognizer *screenEdgePanGestureRecognizer;
@property (nonatomic, strong) UISwipeGestureRecognizer *swipeDown, *swipeUp;


@property (nonatomic, strong) UIToolbar *inputAccessoryView;
@property (nonatomic, strong) UIBarButtonItem *flexibleSpace;
@property (nonatomic, strong) UIBarButtonItem *shareButton, *hideButton, *resetButton, *photoButton;

@property (nonatomic, strong) UIToolbar *headerToolbar;
@property (nonatomic, strong) UISlider *cornerRadiusSlider;

@property (nonatomic, strong) UIImagePickerController *imagePicker;

@property (nonatomic, strong) UIImageView *backgroundImageView;

@end

@implementation ViewController {
    BOOL _canBecomeFirstResponder;
    UIStatusBarStyle _preferredStatusBarStyle;
    BOOL _showStatusBar;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    if (self.view.frame.size.width > 500.0f) {
        [PDPDataManager sharedDataManager].maximumDivisionLevel = 8;
    } else if (self.view.frame.size.height > 400.0f) {
        [PDPDataManager sharedDataManager].maximumDivisionLevel = 7;
    }
    
    [self.view addSubview:self.backgroundImageView];
    [self.view addSubview:self.rootDotContainer];
    _canBecomeFirstResponder = YES;
    [self.view addGestureRecognizer:self.screenEdgePanGestureRecognizer];
    [self.view addGestureRecognizer:self.swipeUp];
    [self.view addGestureRecognizer:self.swipeDown];
    
    _preferredStatusBarStyle = UIStatusBarStyleDefault;
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
    }
    
    return _rootDot;
}

- (UIToolbar *)inputAccessoryView {
    if (!_inputAccessoryView) {
        _inputAccessoryView = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, self.view.frame.size.height, self.view.frame.size.width, 44.0f)];
        [_inputAccessoryView setItems:@[self.shareButton, self.flexibleSpace, self.resetButton, self.flexibleSpace, self.photoButton]
                             animated:NO];
    }
    
    return _inputAccessoryView;
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
        _headerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, 44.0f)];
        [_headerToolbar addSubview:self.cornerRadiusSlider];
    }
    
    return _headerToolbar;
}


#pragma mark - View Controllers

- (UIImagePickerController *)imagePicker {
    if (!_imagePicker) {
        _imagePicker = [[UIImagePickerController alloc] init];
        _imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        _imagePicker.delegate = self;
        _imagePicker.allowsEditing = NO;
        _imagePicker.navigationBarHidden = YES;
    }
    
    return _imagePicker;
}





#pragma mark - Button Actions

- (void)hideButtonTouched:(UIBarButtonItem *)hideButton {
    _canBecomeFirstResponder = NO;
    [self resignFirstResponder];
}

- (void)photoButtonTouched:(UIBarButtonItem *)photoButton {
    [self presentViewController:self.imagePicker
                       animated:YES
                     completion:^{
                         
                     }];
}

- (void)resetButtonTouched:(UIBarButtonItem *)resetButton {
    NSMutableArray *subviews = [[self.view subviews] mutableCopy];
    [subviews addObjectsFromArray:self.rootDotContainer.subviews];
    
    for (PDPDotView *dot in subviews) {
        [dot removeFromSuperview];
    }
    
    self.rootDot = nil;
    [self.view addSubview:self.rootDotContainer];
    [self.rootDotContainer addSubview:self.rootDot];
    [self.rootDotContainer addSubview:self.interceptView];
    self.rootDot.isDivided = NO;
    [self.rootDot layoutSubviews];
}

- (void)shareButtonTouched:(UIBarButtonItem *)shareButton {
    NSLog(@"Share!");
}



#pragma mark - First Responder

- (BOOL)canBecomeFirstResponder {
    return _canBecomeFirstResponder;
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



#pragma mark - Gesture Recognizer Actions

- (void)pannedFromEdge:(UIScreenEdgePanGestureRecognizer *)pan {
    NSLog(@"Edge Panned!");
}

- (void)swiped:(UISwipeGestureRecognizer *)swipe {
    if (swipe.direction == UISwipeGestureRecognizerDirectionDown) {
        _canBecomeFirstResponder = NO;
        [self resignFirstResponder];
    } else if (swipe.direction == UISwipeGestureRecognizerDirectionUp) {
        _canBecomeFirstResponder = YES;
        [self becomeFirstResponder];
    }
    
}



#pragma mark - Image Picker Delegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES
                               completion:^{
                                   
                               }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    [self updateBackgroundColorWithImage:image];
    
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
    self.accentColor1 = [UIColor colorWithHue:1.0f - red
                                   saturation:1.0f - green
                                   brightness:1.0f - blue
                                        alpha:1.0f];
    
    self.inputAccessoryView.barTintColor = self.backgroundColor;
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
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    [self.accentColor1 getHue:&hue
                   saturation:&saturation
                   brightness:&brightness
                        alpha:&alpha];
    for (UIBarButtonItem *barButtonItem in self.inputAccessoryView.items) {
        if (brightness > 0.5f) {
            barButtonItem.tintColor = [UIColor colorWithHue:hue
                                                 saturation:saturation
                                                 brightness:1.0f - brightness
                                                      alpha:1.0f];
        } else {
            barButtonItem.tintColor = [UIColor colorWithHue:hue
                                                 saturation:saturation
                                                 brightness:1.0f - brightness
                                                      alpha:1.0f];
        }
    }
}


#pragma mark - Navigation Controller Delegate



#pragma mark - Status Bar

- (UIStatusBarStyle)preferredStatusBarStyle {
    return _preferredStatusBarStyle;
}

- (BOOL)prefersStatusBarHidden {
    return !_showStatusBar;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationSlide;
}


#pragma mark - Measuring Touches

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchLocation = [touch locationInView:touch.view];
    
    NSArray *allDots = [[[PDPDataManager sharedDataManager] allDots] allObjects];
    for (PDPDotView *dot in allDots) {
        if (CGRectContainsPoint(dot.frame, touchLocation)) {
            if ([dot respondsToSelector:@selector(isDivided)] && !dot.isDivided) {
                dot.isDivided = YES;
                [dot layoutSubviews];
            }
        }
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchLocation = [touch locationInView:touch.view];
    
    NSArray *allDots = [[[PDPDataManager sharedDataManager] allDots] allObjects];
    for (PDPDotView *dot in allDots) {
        if (CGRectContainsPoint(dot.frame, touchLocation)) {
            if ([dot respondsToSelector:@selector(isDivided)] && !dot.isDivided) {
                dot.isDivided = YES;
                [dot layoutSubviews];
            }
        }
    }
}


#pragma mark - Memory Warning

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
