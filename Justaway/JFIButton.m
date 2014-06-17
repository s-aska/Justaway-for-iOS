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
    switch (self.tag) {
        case 1000:
            [[JFITheme sharedTheme] setColorForReplyButton:self active:active];
            break;
        case 1001:
            [[JFITheme sharedTheme] setColorForRetweetButton:self active:active];
            break;
        case 1002:
            [[JFITheme sharedTheme] setColorForFavoriteButton:self active:active];
            break;
            
        default:
            [[JFITheme sharedTheme] setColorForMenuButton:self active:active];
            break;
    }
    _active = active;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
