#import "JFITheme.h"
#import "UIColor+Justaway.h"
#import "SVProgressHUD.h"

@implementation JFITheme

+ (JFITheme *)sharedTheme
{
    static JFITheme *theme;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        theme = [[JFITheme alloc] init];
        [theme setSolarizedLightTheme];
    });
    
    return theme;
}

// TODO
- (void)setDarkTheme
{
    self.name = @"Dark";
    self.statusBarStyle = UIStatusBarStyleLightContent;
    self.mainBackgroundColor = [UIColor colorWithRed:0.10 green:0.10 blue:0.10 alpha:1.0];
    self.mainHighlightBackgroundColor = [UIColor darkGrayColor];
    self.titleTextColor = [UIColor whiteColor];
    self.bodyTextColor = [UIColor whiteColor];
    
    self.displayNameTextColor = [UIColor whiteColor];
    self.screenNameTextColor = [UIColor lightGrayColor];
    self.relativeDateTextColor = [UIColor lightGrayColor];
    self.absoluteDateTextColor = [UIColor lightGrayColor];
    self.clientNameTextColor = [UIColor lightGrayColor];
    
    self.buttonTextColor = [UIColor lightGrayColor];
    self.retweetedTextColor = [UIColor greenLightColor];
    self.favoritedTextColor = [UIColor orangeLightColor];
    
    self.menuBackgroundColor = [UIColor darkGrayColor];
    self.menuTextColor = [UIColor whiteColor];
    self.menuHighlightTextColor = [UIColor blueLightColor];
    self.menuDisabledTextColor = [UIColor grayColor];
    
    [SVProgressHUD setBackgroundColor:self.mainBackgroundColor];
    [SVProgressHUD setForegroundColor:self.titleTextColor];
}

- (void)setLightTheme
{
    self.name = @"Light";
    self.statusBarStyle = UIStatusBarStyleDefault;
    self.mainBackgroundColor = [UIColor colorWithRed:0.97 green:0.97 blue:0.97 alpha:1.0];
    self.mainHighlightBackgroundColor = [UIColor colorWithRed:0.80 green:0.80 blue:0.80 alpha:1.0];
    self.titleTextColor = [UIColor darkGrayColor];
    self.bodyTextColor = [UIColor darkGrayColor];
    
    self.displayNameTextColor = [UIColor darkGrayColor];
    self.screenNameTextColor = [UIColor lightGrayColor];
    self.relativeDateTextColor = [UIColor lightGrayColor];
    self.absoluteDateTextColor = [UIColor lightGrayColor];
    self.clientNameTextColor = [UIColor lightGrayColor];
    
    self.buttonTextColor = [UIColor grayColor];
    self.retweetedTextColor = [UIColor greenDarkColor];
    self.favoritedTextColor = [UIColor orangeDarkColor];
    
    self.menuBackgroundColor = [UIColor colorWithRed:0.90 green:0.90 blue:0.90 alpha:1.0];
    self.menuTextColor = [UIColor darkGrayColor];
    self.menuHighlightTextColor = [UIColor blueDarkColor];
    self.menuDisabledTextColor = [UIColor grayColor];
    
    [SVProgressHUD setBackgroundColor:self.mainBackgroundColor];
    [SVProgressHUD setForegroundColor:self.titleTextColor];
}

- (void)setSolarizedDarkTheme
{
    self.name = @"Solarized Dark";
    self.statusBarStyle = UIStatusBarStyleLightContent;
    
    UIColor *base03  = [UIColor colorWithRed:0.00 green:0.17 blue:0.21 alpha:1.0];
    UIColor *base02  = [UIColor colorWithRed:0.03 green:0.21 blue:0.26 alpha:1.0];
    UIColor *base01  = [UIColor colorWithRed:0.35 green:0.43 blue:0.46 alpha:1.0];
    // UIColor *base00  = [UIColor colorWithRed:0.40 green:0.48 blue:0.51 alpha:1.0];
    // UIColor *base0   = [UIColor colorWithRed:0.51 green:0.58 blue:0.59 alpha:1.0];
    UIColor *base1   = [UIColor colorWithRed:0.58 green:0.63 blue:0.63 alpha:1.0];
    // UIColor *base2   = [UIColor colorWithRed:0.93 green:0.91 blue:0.84 alpha:1.0];
    // UIColor *base3   = [UIColor colorWithRed:0.99 green:0.96 blue:0.89 alpha:1.0];
    UIColor *yellow  = [UIColor colorWithRed:0.71 green:0.54 blue:0.00 alpha:1.0];
    UIColor *orange  = [UIColor colorWithRed:0.80 green:0.29 blue:0.09 alpha:1.0];
    UIColor *red     = [UIColor colorWithRed:0.86 green:0.20 blue:0.18 alpha:1.0];
    UIColor *magenta = [UIColor colorWithRed:0.83 green:0.21 blue:0.51 alpha:1.0];
    // UIColor *violet  = [UIColor colorWithRed:0.42 green:0.44 blue:0.77 alpha:1.0];
    UIColor *blue    = [UIColor colorWithRed:0.15 green:0.55 blue:0.82 alpha:1.0];
    UIColor *cyan    = [UIColor colorWithRed:0.16 green:0.63 blue:0.60 alpha:1.0];
    UIColor *green   = [UIColor colorWithRed:0.52 green:0.60 blue:0.00 alpha:1.0];
    
    self.mainBackgroundColor = base03;
    self.mainHighlightBackgroundColor = base02;
    self.titleTextColor = base1;
    self.bodyTextColor = base1;
    
    self.displayNameTextColor = yellow;
    self.screenNameTextColor = red;
    self.relativeDateTextColor = magenta;
    self.absoluteDateTextColor = blue;
    self.clientNameTextColor = cyan;
    
    self.buttonTextColor = base1;
    self.retweetedTextColor = green;
    self.favoritedTextColor = orange;
    
    self.menuBackgroundColor = base02;
    self.menuTextColor = base1;
    self.menuHighlightTextColor = blue;
    self.menuDisabledTextColor = base01;
    
    [SVProgressHUD setBackgroundColor:self.mainBackgroundColor];
    [SVProgressHUD setForegroundColor:self.titleTextColor];
}

- (void)setSolarizedLightTheme
{
    self.name = @"Solarized Light";
    self.statusBarStyle = UIStatusBarStyleDefault;
    
    // UIColor *base03  = [UIColor colorWithRed:0.00 green:0.17 blue:0.21 alpha:1.0];
    // UIColor *base02  = [UIColor colorWithRed:0.03 green:0.21 blue:0.26 alpha:1.0];
    UIColor *base01  = [UIColor colorWithRed:0.35 green:0.43 blue:0.46 alpha:1.0];
    // UIColor *base00  = [UIColor colorWithRed:0.40 green:0.48 blue:0.51 alpha:1.0];
    // UIColor *base0   = [UIColor colorWithRed:0.51 green:0.58 blue:0.59 alpha:1.0];
    UIColor *base1   = [UIColor colorWithRed:0.58 green:0.63 blue:0.63 alpha:1.0];
    UIColor *base2   = [UIColor colorWithRed:0.93 green:0.91 blue:0.84 alpha:1.0];
    UIColor *base3   = [UIColor colorWithRed:0.99 green:0.96 blue:0.89 alpha:1.0];
    UIColor *yellow  = [UIColor colorWithRed:0.71 green:0.54 blue:0.00 alpha:1.0];
    UIColor *orange  = [UIColor colorWithRed:0.80 green:0.29 blue:0.09 alpha:1.0];
    UIColor *red     = [UIColor colorWithRed:0.86 green:0.20 blue:0.18 alpha:1.0];
    UIColor *magenta = [UIColor colorWithRed:0.83 green:0.21 blue:0.51 alpha:1.0];
    // UIColor *violet  = [UIColor colorWithRed:0.42 green:0.44 blue:0.77 alpha:1.0];
    UIColor *blue    = [UIColor colorWithRed:0.15 green:0.55 blue:0.82 alpha:1.0];
    UIColor *cyan    = [UIColor colorWithRed:0.16 green:0.63 blue:0.60 alpha:1.0];
    UIColor *green   = [UIColor colorWithRed:0.52 green:0.60 blue:0.00 alpha:1.0];
    
    self.mainBackgroundColor = base3;
    self.mainHighlightBackgroundColor = base2;
    self.titleTextColor = base01;
    self.bodyTextColor = base01;
    
    self.displayNameTextColor = yellow;
    self.screenNameTextColor = red;
    self.relativeDateTextColor = magenta;
    self.absoluteDateTextColor = blue;
    self.clientNameTextColor = green;
    
    self.buttonTextColor = base1;
    self.retweetedTextColor = cyan;
    self.favoritedTextColor = orange;
    
    self.menuBackgroundColor = base2;
    self.menuTextColor = base01;
    self.menuHighlightTextColor = blue;
    self.menuDisabledTextColor = base1;
    
    [SVProgressHUD setBackgroundColor:self.mainBackgroundColor];
    [SVProgressHUD setForegroundColor:self.titleTextColor];
}

- (void)setMonokaiTheme
{
    self.name = @"Monokai";
    self.statusBarStyle = UIStatusBarStyleLightContent;
    
    UIColor *black = [UIColor colorWithRed:0.15 green:0.16 blue:0.13 alpha:1.0];
    UIColor *red = [UIColor colorWithRed:0.98 green:0.15 blue:0.45 alpha:1.0];
    UIColor *green = [UIColor colorWithRed:0.65 green:0.89 blue:0.18 alpha:1.0];
    UIColor *orange = [UIColor colorWithRed:0.99 green:0.59 blue:0.12 alpha:1.0];
    UIColor *blue = [UIColor colorWithRed:0.40 green:0.85 blue:0.94 alpha:1.0];
    UIColor *violet = [UIColor colorWithRed:0.68 green:0.51 blue:1.00 alpha:1.0];
    UIColor *yellow = [UIColor colorWithRed:0.90 green:0.86 blue:0.45 alpha:1.0];
    UIColor *gray = [UIColor colorWithRed:0.46 green:0.44 blue:0.37 alpha:1.0];
    
    self.mainBackgroundColor = black;
    self.mainHighlightBackgroundColor = [UIColor darkGrayColor];
    self.titleTextColor = [UIColor whiteColor];
    self.bodyTextColor = [UIColor whiteColor];
    
    self.displayNameTextColor = yellow;
    self.screenNameTextColor = red;
    self.relativeDateTextColor = green;
    self.absoluteDateTextColor = violet;
    self.clientNameTextColor = blue;
    
    self.buttonTextColor = [UIColor lightGrayColor];
    self.retweetedTextColor = green;
    self.favoritedTextColor = orange;
    
    self.menuBackgroundColor = gray;
    self.menuTextColor = [UIColor whiteColor];
    self.menuHighlightTextColor = [UIColor blueLightColor];
    self.menuDisabledTextColor = [UIColor grayColor];
    
    [SVProgressHUD setBackgroundColor:self.mainBackgroundColor];
    [SVProgressHUD setForegroundColor:self.titleTextColor];
}

- (void)setColorForMenuButton:(JFIButton *)button active:(BOOL)active
{
    UIColor *normalColor = active ? self.menuHighlightTextColor : self.menuTextColor;
    [button setTitleColor:normalColor forState:UIControlStateNormal];
    [button setTitleColor:self.menuDisabledTextColor forState:UIControlStateHighlighted];
    [button setTitleColor:self.menuDisabledTextColor forState:UIControlStateDisabled];
}

- (void)setColorForReplyButton:(JFIButton *)button active:(BOOL)active
{
    [button setTitleColor:self.buttonTextColor forState:UIControlStateNormal];
}

- (void)setColorForFavoriteButton:(JFIButton *)button active:(BOOL)active animated:(BOOL)animated
{
    UIColor *color = active ? self.favoritedTextColor : self.buttonTextColor;
    [button setTitleColor:color forState:UIControlStateNormal];
    if (active && animated) {
        [button animation];
    }
}

- (void)setColorForRetweetButton:(JFIButton *)button active:(BOOL)active animated:(BOOL)animated
{
    if (button.isEnabled) {
        UIColor *color = active ? self.retweetedTextColor : self.buttonTextColor;
        [button setTitleColor:color forState:UIControlStateNormal];
        if (active && animated) {
            [button animation];
        }
    } else {
        [button setTitleColor:[self.buttonTextColor colorWithAlphaComponent:.3] forState:UIControlStateDisabled];
    }
}

@end
