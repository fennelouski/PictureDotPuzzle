//
//  PDPDataManager.m
//  
//
//  Created by HAI on 12/16/15.
//
//

#import "PDPDataManager.h"
#import "UIImage+BlurredFrame.h"
#include <sys/types.h>
#include <sys/sysctl.h>

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
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        if ([defaults integerForKey:@"Number of loads"] < 2) {
            self.image = [UIImage imageNamed:@"2.jpg"];
            [defaults setInteger:[defaults integerForKey:@"Number of loads"] + 1
                          forKey:@"Number of loads"];
        } else {
            self.image = [UIImage imageNamed:[NSString stringWithFormat:@"%d.jpg", arc4random_uniform(8) + 1]];
        }
        
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
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self calculateMaximumDivisionLevel];
        });
        
        self.allDots = [[NSHashTable alloc] initWithOptions:NSPointerFunctionsWeakMemory
                                                   capacity:_maximumDivisionLevel];
        self.reserveDots = [[NSHashTable alloc] initWithOptions:NSPointerFunctionsWeakMemory
                                                       capacity:_maximumDivisionLevel];
        self.canMutateAllDots = YES;
    }
    
    return self;
}

- (void)calculateMaximumDivisionLevel {
    if ([UIApplication sharedApplication].keyWindow.frame.size.width > 92024.0f) {
        self.maximumDivisionLevel = 8;
        _totalNumberOfDotsPossible = 87380;
    } else if ([UIApplication sharedApplication].keyWindow.frame.size.width > 91024.0f) {
        self.maximumDivisionLevel = 7;
        _totalNumberOfDotsPossible = 21844;
    } else if ([UIApplication sharedApplication].keyWindow.frame.size.width > 400.0f) {
        self.maximumDivisionLevel = 6;
        _totalNumberOfDotsPossible = 5460;
    } else if ([UIApplication sharedApplication].keyWindow.frame.size.width > 200.0f) {
        self.maximumDivisionLevel = 5;
        _totalNumberOfDotsPossible = 1364;
    } else {
        self.maximumDivisionLevel = 4;
        _totalNumberOfDotsPossible = 600;
        NSLog(@"Low res %g", [UIApplication sharedApplication].keyWindow.frame.size.width);
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








- (NSString *) platform{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}

- (NSString *)deviceType {
    NSString *platform = [self platform];
    
    if ([platform isEqualToString:@"iPhone1,1"])    return @"iPhone 1G";
    if ([platform isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
    if ([platform isEqualToString:@"iPhone2,1"])    return @"iPhone 3GS";
    if ([platform isEqualToString:@"iPhone3,1"])    return @"iPhone 4";
    if ([platform isEqualToString:@"iPhone3,3"])    return @"Verizon iPhone 4";
    if ([platform isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
    if ([platform isEqualToString:@"iPhone5,1"])    return @"iPhone 5 (GSM)";
    if ([platform isEqualToString:@"iPhone5,2"])    return @"iPhone 5 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone5,3"])    return @"iPhone 5c (GSM)";
    if ([platform isEqualToString:@"iPhone5,4"])    return @"iPhone 5c (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone6,1"])    return @"iPhone 5s (GSM)";
    if ([platform isEqualToString:@"iPhone6,2"])    return @"iPhone 5s (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone7,1"])    return @"iPhone 6 Plus";
    if ([platform isEqualToString:@"iPhone7,2"])    return @"iPhone 6";
    if ([platform isEqualToString:@"iPhone8,1"])    return @"iPhone 6s Plus";
    if ([platform isEqualToString:@"iPhone8,2"])    return @"iPhone 6s";
    if ([platform isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
    if ([platform isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
    if ([platform isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
    if ([platform isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
    if ([platform isEqualToString:@"iPod5,1"])      return @"iPod Touch 5G";
    if ([platform isEqualToString:@"iPad1,1"])      return @"iPad";
    if ([platform isEqualToString:@"iPad2,1"])      return @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,2"])      return @"iPad 2 (GSM)";
    if ([platform isEqualToString:@"iPad2,3"])      return @"iPad 2 (CDMA)";
    if ([platform isEqualToString:@"iPad2,4"])      return @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,5"])      return @"iPad Mini (WiFi)";
    if ([platform isEqualToString:@"iPad2,6"])      return @"iPad Mini (GSM)";
    if ([platform isEqualToString:@"iPad2,7"])      return @"iPad Mini (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad3,1"])      return @"iPad 3 (WiFi)";
    if ([platform isEqualToString:@"iPad3,2"])      return @"iPad 3 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad3,3"])      return @"iPad 3 (GSM)";
    if ([platform isEqualToString:@"iPad3,4"])      return @"iPad 4 (WiFi)";
    if ([platform isEqualToString:@"iPad3,5"])      return @"iPad 4 (GSM)";
    if ([platform isEqualToString:@"iPad3,6"])      return @"iPad 4 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad4,1"])      return @"iPad Air (WiFi)";
    if ([platform isEqualToString:@"iPad4,2"])      return @"iPad Air (Cellular)";
    if ([platform isEqualToString:@"iPad4,4"])      return @"iPad mini 2G (WiFi)";
    if ([platform isEqualToString:@"iPad4,5"])      return @"iPad mini 2G (Cellular)";
    if ([platform isEqualToString:@"iPad5,3"])      return @"iPad Air 2 (WiFi)";
    if ([platform isEqualToString:@"iPad5,4"])      return @"iPad Air 2 (Cellular)";
    if ([platform isEqualToString:@"i386"])         return @"Simulator";
    if ([platform isEqualToString:@"x86_64"])       return @"Simulator";
    
    NSLog(@"Unrecognized Device: %@", platform);
    
    return platform;
}






@end
