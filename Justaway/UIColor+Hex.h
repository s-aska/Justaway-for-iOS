#import <UIKit/UIKit.h>

@interface UIColor (Hex)

+ (UIColor *)colorWithHex:(NSString *)colorCode;
+ (UIColor *)colorWithHex:(NSString *)colorCode alpha:(CGFloat)alpha;

@end
