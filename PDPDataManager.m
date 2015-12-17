//
//  PDPDataManager.m
//  
//
//  Created by HAI on 12/16/15.
//
//

#import "PDPDataManager.h"

static NSString * const animationDurationKey = @"Animation Duration K£y";

@implementation PDPDataManager {
    NSInteger _maximumDivisionLevel;
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
        
        self.allDots = [NSMutableSet new];
    }
    
    return self;
}

- (NSInteger)maximumDivisionLevel {
    return  _maximumDivisionLevel;
}


- (void)setMaximumDivisionLevel:(NSInteger)maximumDivisionLevel {
    _maximumDivisionLevel = maximumDivisionLevel;
}
@end
