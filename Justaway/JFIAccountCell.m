#import "JFIAccountCell.h"

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

- (void)setLabelTexts:(NSDictionary *)account
{
    self.screenNameLabel.text = [@"@" stringByAppendingString:[account valueForKeyPath:@"screenName"]];
}

@end
