//
//  PDPDataManager.m
//  
//
//  Created by HAI on 12/16/15.
//
//

#import "PDPDataManager.h"
#import "UIImage+BlurredFrame.h"

static NSString * const maximumDivisionLevelKey = @"Maximum Division Level K£y";
static NSString * const totalNumberOfDotsPossibleKey = @"Total Number of Dots Possible K£y";

static NSString * const animationDurationKey = @"Animation Duration K£y";
static NSString * const automationDurationKey = @"Automation Duration K£y";

@implementation PDPDataManager {
    NSInteger _maximumDivisionLevel, _totalNumberOfDotsPossible;
    UIImage *_image;
}

+ (instancetype)sharedDataManager {
    static PDPDataManager *sharedDataManager;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDataManager = [[PDPDataManager alloc] init];
    });
    
    return sharedDataManager;
}

- (id)init {
    self = [super init];
    if (self) {
        self.cornerRadius = 0.5f;
        self.image = [UIImage imageNamed:@"13 Rose.jpg"];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        self.animationDuration = [defaults floatForKey:animationDurationKey];
        if (self.animationDuration == 0.0f) {
            self.animationDuration = 0.35f;
        }
        
        self.automationDuration = [defaults floatForKey:automationDurationKey];
        if (self.automationDuration == 0.0f) {
            self.automationDuration = 6.0f;
        }
        
        _maximumDivisionLevel = [defaults integerForKey:maximumDivisionLevelKey];
        _totalNumberOfDotsPossible = [defaults integerForKey:totalNumberOfDotsPossibleKey];
        if (_maximumDivisionLevel < 4 || _totalNumberOfDotsPossible < 100) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35f /*Long enough for the key window to load and have a frame size*/ * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self calculateMaximumDivisionLevel];
            });
            
            _maximumDivisionLevel = 5;
        }
        
        
        self.allDots = [[NSHashTable alloc] initWithOptions:NSPointerFunctionsWeakMemory
                                                   capacity:_maximumDivisionLevel];
        self.reserveDots = [[NSHashTable alloc] initWithOptions:NSPointerFunctionsWeakMemory
                                                       capacity:_maximumDivisionLevel];
        self.canMutateAllDots = YES;
    }
    
    return self;
}

- (void)calculateMaximumDivisionLevel {
    if ([UIApplication sharedApplication].keyWindow.frame.size.width > 1024.0f) {
        self.maximumDivisionLevel = 8;
        _totalNumberOfDotsPossible = 87380;
    } else if ([UIApplication sharedApplication].keyWindow.frame.size.width > 460.0f) {
        self.maximumDivisionLevel = 7;
        _totalNumberOfDotsPossible = 21844;
    } else if ([UIApplication sharedApplication].keyWindow.frame.size.width > 300.0f) {
        self.maximumDivisionLevel = 6;
        _totalNumberOfDotsPossible = 5460;
    } else {
        self.maximumDivisionLevel = 5;
        _totalNumberOfDotsPossible = 1364;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:self.maximumDivisionLevel
                  forKey:maximumDivisionLevelKey];
    [defaults setInteger:_totalNumberOfDotsPossible
                  forKey:totalNumberOfDotsPossibleKey];
}

- (NSInteger)maximumDivisionLevel {
    return  _maximumDivisionLevel;
}


- (void)setMaximumDivisionLevel:(NSInteger)maximumDivisionLevel {
    _maximumDivisionLevel = maximumDivisionLevel;
}

- (NSInteger)totalNumberOfDotsPossible {
    return _totalNumberOfDotsPossible;
}

- (float)progress {
    return sqrtf((float)_dotNumber / (float)_totalNumberOfDotsPossible);
}



- (UIImage *)image {
    return _image;
}

- (void)setImage:(UIImage *)image {
    _image = image;
    
    if (_image.size.width > [UIScreen mainScreen].bounds.size.width) {
        _image = [UIImage imageWithImage:image scaledToSize:CGSizeMake([UIScreen mainScreen].bounds.size.width,
                                                                       [UIScreen mainScreen].bounds.size.width)];
    }
}





@end
