#import "JFIButton.h"

@implementation JFIButton

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self.titleLabel setFont:[UIFont fontWithName:@"fontello" size:self.titleLabel.font.pointSize]];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self.titleLabel setFont:[UIFont fontWithName:@"fontello" size:self.titleLabel.font.pointSize]];
    }
    return self;
}

@end
