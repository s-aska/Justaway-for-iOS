#import "JFIButton.h"

@implementation JFIButton

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self.titleLabel setFont:[UIFont fontWithName:@"fontello" size:self.titleLabel.font.pointSize]];
    [self setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    [self setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self.titleLabel setFont:[UIFont fontWithName:@"fontello" size:self.titleLabel.font.pointSize]];
        [self setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [self setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
        [self setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    }
    return self;
}

@end
