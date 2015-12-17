//
//  PDPTouchInterceptView.h
//  
//
//  Created by HAI on 12/16/15.
//
//

#import <UIKit/UIKit.h>

@protocol PDPTouchInterceptViewDelegate <NSObject>

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;

@end

@interface PDPTouchInterceptView : UIView

@property (assign)  id <PDPTouchInterceptViewDelegate> delegate;

@end
