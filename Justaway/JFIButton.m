#import "JFIButton.h"
#import "JFITheme.h"

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
}

- (void)setActive:(BOOL)active
{
    [[JFITheme sharedTheme] setColorForMenuButton:self active:active];
    _active = active;
}

@end
