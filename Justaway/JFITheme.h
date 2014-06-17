#import <Foundation/Foundation.h>

@interface JFITheme : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) UIStatusBarStyle statusBarStyle;
@property (nonatomic) UIColor *mainBackgroundColor;
@property (nonatomic) UIColor *mainHighlightBackgroundColor;
@property (nonatomic) UIColor *titleTextColor;
@property (nonatomic) UIColor *bodyTextColor;

@property (nonatomic) UIColor *displayNameTextColor;
@property (nonatomic) UIColor *screenNameTextColor;
@property (nonatomic) UIColor *relativeDateTextColor;
@property (nonatomic) UIColor *absoluteDateTextColor;
@property (nonatomic) UIColor *clientNameTextColor;

@property (nonatomic) UIColor *buttonTextColor;
@property (nonatomic) UIColor *retweetedTextColor;
@property (nonatomic) UIColor *favoritedTextColor;

@property (nonatomic) UIColor *menuBackgroundColor;
@property (nonatomic) UIColor *menuTextColor;
@property (nonatomic) UIColor *menuHighlightTextColor;
@property (nonatomic) UIColor *menuDisabledTextColor;

+ (JFITheme *)sharedTheme;

- (void)setDarkTheme;
- (void)setLightTheme;
- (void)setSolarizedDarkTheme;
- (void)setSolarizedLightTheme;
- (void)setMonokaiTheme;

- (void)setColorForMenuButton:(UIButton *)button active:(BOOL)active;
- (void)setColorForReplyButton:(UIButton *)button active:(BOOL)active;
- (void)setColorForFavoriteButton:(UIButton *)button active:(BOOL)active;
- (void)setColorForRetweetButton:(UIButton *)button active:(BOOL)active;

@end
