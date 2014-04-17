#import <Foundation/Foundation.h>

@interface JFITheme : NSObject

+ (JFITheme *)sharedTheme;

+ (UIColor *)blueBright;
+ (UIColor *)blueLight;
+ (UIColor *)blueDark;
+ (UIColor *)greenLight;
+ (UIColor *)greenDark;
+ (UIColor *)orangeLight;
+ (UIColor *)orangeDark;
+ (UIColor *)redLight;
+ (UIColor *)redDark;

- (void)setColorForMenuButton:(UIButton *)button active:(BOOL)active;
- (void)setColorForFavoriteButton:(UIButton *)button active:(BOOL)active;
- (void)setColorForRetweetButton:(UIButton *)button active:(BOOL)active;

@end
