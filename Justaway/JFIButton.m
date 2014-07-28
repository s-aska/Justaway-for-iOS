#import "JFIButton.h"
#import "JFITheme.h"
#import "JFIConstants.h"

@implementation JFIButton

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setDefault];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setDefault];
    }
    return self;
}

- (void)setDefault
{
    [self.titleLabel setFont:[UIFont fontWithName:@"fontello" size:self.titleLabel.font.pointSize]];
    self.active = NO;
    
    // テーマ設定
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setTheme)
                                                 name:JFISetThemeNotification
                                               object:nil];
}

- (void)setTheme
{
    [self setActive:self.active];
}

- (void)setActive:(BOOL)active
{
    [self setActive:self.active animated:NO];
}

- (void)setActive:(BOOL)active animated:(BOOL)animated
{
    // 状態変化がない場合はアニメーションしない
    if (active == _active) {
        animated = NO;
    }
    switch (self.tag) {
        case 1000:
            [[JFITheme sharedTheme] setColorForReplyButton:self active:active];
            break;
        case 1001:
            [[JFITheme sharedTheme] setColorForRetweetButton:self active:active animated:animated];
            break;
        case 1002:
            [[JFITheme sharedTheme] setColorForFavoriteButton:self active:active animated:animated];
            break;
            
        default:
            [[JFITheme sharedTheme] setColorForMenuButton:self active:active];
            break;
    }
    _active = active;
}

- (void)animation
{
    self.transform = CGAffineTransformMakeScale(1, 1);
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.transform = CGAffineTransformMakeScale(1.4f, 1.4f);
                         [UIView animateWithDuration:0.3
                                               delay:0
                                             options:UIViewAnimationOptionCurveEaseIn
                                          animations:^{
                                              self.transform = CGAffineTransformMakeScale(1, 1);
                                          }
                                          completion:^(BOOL finished){}
                          ];
                         
                     }
                     completion:^(BOOL finished){}
     ];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
