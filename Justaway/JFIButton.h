#import <UIKit/UIKit.h>

@interface JFIButton : UIButton

@property (nonatomic, setter = setActive:) BOOL active;

- (void)setActive:(BOOL)active animated:(BOOL)animated;
- (void)animation;

@end
