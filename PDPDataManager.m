//
//  PDPDataManager.m
//  
//
//  Created by HAI on 12/16/15.
//
//

#import "PDPDataManager.h"
#import "UIImage+BlurredFrame.h"
#import "Picture Dot Puzzle/PDPRenderCore.h"
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
        self.image = [UIImage imageNamed:@"OriginalSample.jpg"];
        
        self.animationDuration = [defaults objectForKey:animationDurationKey] ? [defaults doubleForKey:animationDurationKey] : 0.35;
        
        self.automationDuration = [defaults objectForKey:automationDurationKey] ? [defaults doubleForKey:automationDurationKey] : 6.0;
        
        _maximumDivisionLevel = [defaults integerForKey:maximumDivisionLevelKey];
        _totalNumberOfDotsPossible = [defaults integerForKey:totalNumberOfDotsPossibleKey];
        
        [self calculateMaximumDivisionLevel];

        self.allDots = [[NSHashTable alloc] initWithOptions:NSPointerFunctionsWeakMemory
                                                   capacity:_maximumDivisionLevel];
        self.reserveDots = [[NSHashTable alloc] initWithOptions:NSPointerFunctionsWeakMemory
                                                       capacity:_maximumDivisionLevel];
        self.canMutateAllDots = YES;
    }
    
    return self;
}

- (void)calculateMaximumDivisionLevel {
    CGFloat width = MIN(UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
    self.maximumDivisionLevel = width > 400 ? 6 : width > 300 ? 5 : 4;
    _totalNumberOfDotsPossible = PDPDotCount((unsigned)self.maximumDivisionLevel);
}

- (void)setAnimationDuration:(NSTimeInterval)value {
    _animationDuration = MIN(1.0, MAX(0.05, value));
    [NSUserDefaults.standardUserDefaults setDouble:_animationDuration forKey:animationDurationKey];
}

- (void)setAutomationDuration:(NSTimeInterval)value {
    _automationDuration = MIN(20.0, MAX(2.0, value));
    [NSUserDefaults.standardUserDefaults setDouble:_automationDuration forKey:automationDurationKey];
}

- (NSInteger)maximumDivisionLevel {
    return  _maximumDivisionLevel;
}


- (void)setMaximumDivisionLevel:(NSInteger)maximumDivisionLevel {
    _maximumDivisionLevel = MIN(8, MAX(1, maximumDivisionLevel));
    _totalNumberOfDotsPossible = PDPDotCount((unsigned)_maximumDivisionLevel);
}

- (NSInteger)totalNumberOfDotsPossible {
    return _totalNumberOfDotsPossible;
}

- (float)progress {
    return PDPProgress(MAX(0, _dotNumber), MAX(0, _totalNumberOfDotsPossible));
}



- (UIImage *)image {
    return _image;
}

- (void)setImage:(UIImage *)image {
    if (!image || image.size.width <= 0 || image.size.height <= 0) { _image = nil; return; }
    CGFloat edge = MIN(1024, MIN(image.size.width * image.scale, image.size.height * image.scale));
    CGSize size = CGSizeMake(edge, edge);
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.scale = 1;
    format.opaque = NO;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size format:format];
    _image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        [image drawInRect:PDPAspectFillRect(image.size, size)];
    }];
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
