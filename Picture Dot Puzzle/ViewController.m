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

@interface ViewController ()  <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) NSMutableArray *dots;

@property (nonatomic) NSInteger numberOfRows, numberOfColumns;

@property (nonatomic, strong) UIView *rootDotContainer;
@property (nonatomic, strong) PDPDotView *rootDot;

@property (nonatomic, strong) UIScreenEdgePanGestureRecognizer *screenEdgePanGestureRecognizer;
@property (nonatomic, strong) UISwipeGestureRecognizer *swipeDown, *swipeUp;


@property (nonatomic, strong) UIToolbar *inputAccessoryView;
@property (nonatomic, strong) UIBarButtonItem *flexibleSpace;
@property (nonatomic, strong) UIBarButtonItem *shareButton, *hideButton, *resetButton, *photoButton;

@property (nonatomic, strong) UIImagePickerController *imagePicker;

@property (nonatomic, strong) UIImageView *backgroundImageView;

@end

@implementation ViewController {
    BOOL _canBecomeFirstResponder;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.view addSubview:self.backgroundImageView];
    [self.view addSubview:self.rootDotContainer];
    _canBecomeFirstResponder = YES;
    [self.view addGestureRecognizer:self.screenEdgePanGestureRecognizer];
    [self.view addGestureRecognizer:self.swipeUp];
    [self.view addGestureRecognizer:self.swipeDown];
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

- (UIView *)rootDotContainer {
    if (!_rootDotContainer) {
        _rootDotContainer = [[UIView alloc] initWithFrame:CGRectMake(0.0f,
                                                                     0.0f,
                                                                     self.view.frame.size.width,
                                                                     self.view.frame.size.width)];
        _rootDotContainer.center = self.view.center;
        [_rootDotContainer addSubview:self.rootDot];
    }
    
    return _rootDotContainer;
}

- (PDPDotView *)rootDot {
    if (!_rootDot) {
        NSLog(@"Creating!");
        _rootDot = [[PDPDotView alloc] initWithFrame:self.rootDotContainer.bounds];
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
                                                        style:UIBarButtonItemStylePlain
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
        NSLog(@"Dot!");
        [dot removeFromSuperview];
    }
    
    self.rootDot = nil;
    [self.view addSubview:self.rootDotContainer];
    [self.rootDotContainer addSubview:self.rootDot];
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
    
    [[PDPDataManager sharedDataManager] setImage:image];
    
    [self.rootDot layoutSubviews];
    
    // find image view
    
    [picker dismissViewControllerAnimated:YES
                               completion:^{
                                   
                               }];
}



#pragma mark - Navigation Controller Delegate




#pragma mark - Memory Warning

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
