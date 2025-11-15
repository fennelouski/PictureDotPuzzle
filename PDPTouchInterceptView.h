//
//  PDPTouchInterceptView.h
//
//
//  Created by HAI on 12/16/15.
//
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PDPTouchInterceptViewDelegate <NSObject>

- (void)touchesMoved:(NSSet *)touches withEvent:(nullable UIEvent *)event;
- (void)touchesBegan:(NSSet *)touches withEvent:(nullable UIEvent *)event;

@end

@interface PDPTouchInterceptView : UIView

@property (nonatomic, weak, nullable) id <PDPTouchInterceptViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
