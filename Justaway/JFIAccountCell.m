#import "JFIAccountCell.h"
#import "JFIAccount.h"
#import "JFITheme.h"
#import "JFIAppDelegate.h"

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
    self.userID = account.userID;
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

- (IBAction)removeAction:(id)sender
{
    [[[UIAlertView alloc]
      initWithTitle:@"Remove account"
      message:[NSString stringWithFormat:@"remove %@?", self.displayNameLabel.text]
      delegate:self
      cancelButtonTitle:@"Cancel"
      otherButtonTitles:@"OK", nil
      ] show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"[%@] %s userID:%@ buttonIndex:%i", NSStringFromClass([self class]), sel_getName(_cmd), self.userID, buttonIndex);
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    switch (buttonIndex) {
        case 1:
            [delegate removeAccount:self.userID];
            break;
            
        default:
            break;
    }
}

@end
