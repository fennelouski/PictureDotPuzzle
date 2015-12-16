//
//  ViewController.m
//  Picture Dot Puzzle
//
//  Created by HAI on 12/16/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, strong) NSMutableArray *dots;

@property (nonatomic) NSInteger numberOfRows, numberOfColumns;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    if (!self.dots) {
        self.dots = [NSMutableArray new];
        self.numberOfRows = 10;
        self.numberOfColumns = 10;
    }
    
    [self layoutDots];
    for (UIView *dot in self.dots) {
        [self.view addSubview:dot];
    }
    
//    [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:1.0f]
//                             interval:1.0f
//                               target:self
//                             selector:@selector(layoutDots)
//                             userInfo:nil
//                              repeats:YES];
//    [NSTimer timerWithTimeInterval:1.0f
//                            target:self
//                          selector:@selector(layoutDots)
//                          userInfo:nil
//                           repeats:YES];
}

- (void)layoutDots {
    NSLog(@"Random Layout");
    if (self.dots) {
        for (UIView *dot in self.dots) {
            [dot removeFromSuperview];
        }
        
        [self.dots removeAllObjects];
        
        self.numberOfRows += arc4random()%3 - 1;
        self.numberOfColumns += arc4random()%3 - 1;
        if (self.numberOfRows <= 0) {
            self.numberOfRows = 1;
        }
        
        if ( self.numberOfColumns <= 0) {
            self.numberOfColumns = 1;
        }
    } else {
        self.dots = [NSMutableArray new];
    }
    
    for (int row = 0; row < self.numberOfRows; row++) {
        for (int column = 0; column < self.numberOfColumns; column++) {
            UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(0.0f,
                                                                   0.0f,
                                                                   self.view.frame.size.width / (self.numberOfColumns + 1),
                                                                   self.view.frame.size.width / (self.numberOfColumns + 1))];
            dot.layer.cornerRadius = dot.frame.size.width * 0.5f;
            dot.clipsToBounds = YES;
            dot.backgroundColor = [UIColor colorWithRed:(float)row / (float) self.numberOfRows
                                                  green:(float)column / (float) self.numberOfColumns
                                                   blue:(float) (row + column) / (self.numberOfRows + self.numberOfColumns)
                                                  alpha:1.0f];
            [self.dots addObject:dot];
            
            dot.center = CGPointMake(((float)(column + 1) / (float) (self.numberOfColumns + 1)) * self.view.frame.size.width,
                                     ((float)(row    + 1) / (float) (self.numberOfRows    + 1)) * self.view.frame.size.height);
        }
    }
    
    for (UIView *dot in self.dots) {
        [self.view addSubview:dot];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
