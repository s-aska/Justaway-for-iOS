#import "JFITheme.h"

@implementation JFITheme

+ (JFITheme *)sharedTheme
{
    static JFITheme *theme;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        theme = [[JFITheme alloc] init];
    });
    
    return theme;
}

+ (UIColor *)blueBright
{
    return [UIColor colorWithRed:0.00 green:0.87 blue:1.00 alpha:1.0];
}

+ (UIColor *)blueLight
{
    return [UIColor colorWithRed:0.20 green:0.71 blue:0.90 alpha:1.0];
}

+ (UIColor *)blueDark
{
    return [UIColor colorWithRed:0.00 green:0.60 blue:0.80 alpha:1.0];
}

+ (UIColor *)greenLight
{
    return [UIColor colorWithRed:0.60 green:0.80 blue:0.00 alpha:1.0];
}

+ (UIColor *)greenDark
{
    return [UIColor colorWithRed:0.40 green:0.60 blue:0.00 alpha:1.0];
}

+ (UIColor *)orangeLight
{
    return [UIColor colorWithRed:1.00 green:0.73 blue:0.20 alpha:1.0];
}

+ (UIColor *)orangeDark
{
    return [UIColor colorWithRed:1.00 green:0.53 blue:0.00 alpha:1.0];
}

+ (UIColor *)redLight
{
    return [UIColor colorWithRed:1.00 green:0.27 blue:0.27 alpha:1.0];
}

+ (UIColor *)redDark
{
    return [UIColor colorWithRed:1.00 green:0.00 blue:0.00 alpha:1.0];
}

- (void)setColorForMenuButton:(UIButton *)button active:(BOOL)active
{
    UIColor *normalColor = active ? [JFITheme blueDark] : [UIColor whiteColor];
    [button setTitleColor:normalColor forState:UIControlStateNormal];
    [button setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [button setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
}

- (void)setColorForFavoriteButton:(UIButton *)button active:(BOOL)active
{
    UIColor *color = active ? [JFITheme orangeLight] : [UIColor lightGrayColor];
    [button setTitleColor:color forState:UIControlStateNormal];
}

- (void)setColorForRetweetButton:(UIButton *)button active:(BOOL)active
{
    UIColor *color = active ? [JFITheme greenLight] : [UIColor lightGrayColor];
    [button setTitleColor:color forState:UIControlStateNormal];
}

@end
