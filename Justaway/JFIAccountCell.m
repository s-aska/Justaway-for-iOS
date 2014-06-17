#import "JFIAccountCell.h"
#import "JFIAccount.h"
#import "JFITheme.h"

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
    [self setTheme];
    self.displayNameLabel.text = account.displayName;
    self.screenNameLabel.text = [@"@" stringByAppendingString:account.screenName];
}

- (void)setTheme
{
    JFITheme *theme = [JFITheme sharedTheme];
    if ([self.themeName isEqualToString:theme.name]) {
        return;
    }
    self.themeName = theme.name;
    [self setBackgroundColor:theme.mainBackgroundColor];
    [self.displayNameLabel setTextColor:theme.displayNameTextColor];
    [self.screenNameLabel setTextColor:theme.screenNameTextColor];
}

@end
