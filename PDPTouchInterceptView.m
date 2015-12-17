//
//  PDPTouchInterceptView.m
//  
//
//  Created by HAI on 12/16/15.
//
//

#import "PDPTouchInterceptView.h"

@implementation PDPTouchInterceptView

//- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//    UITouch *touch = [[event allTouches] anyObject];
//    
//    if ([self.delegate respondsToSelector:@selector(touchesBegan:withEvent:)]) {
//        [self.delegate touchesBegan:touches withEvent:event];
//    } else {
//        NSLog(@"Touch Intercept View's delegate does not respond to \"touchesBegan:withEvent:\"");
//    }
//}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    
    if ([self.delegate respondsToSelector:@selector(touchesMoved:withEvent:)]) {
        [self.delegate touchesMoved:touches withEvent:event];
    }
}

@end
