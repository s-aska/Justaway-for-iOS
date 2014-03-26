#import "JFIAccountCell.h"
#import "JFIAccount.h"

@implementation JFIAccountCell

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void)setLabelTexts:(JFIAccount *)account
{
    self.displayNameLabel.text = account.displayName;
    self.screenNameLabel.text = [@"@" stringByAppendingString:account.screenName];
}

@end
