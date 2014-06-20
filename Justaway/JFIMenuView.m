#import "JFIMenuView.h"
#import "JFIConstants.h"
#import "JFITheme.h"

@implementation JFIMenuView

- (void)awakeFromNib
{
    [self setTheme];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setTheme)
                                                 name:JFISetThemeNotification
                                               object:nil];
}

- (void)setTheme
{
    [self setBackgroundColor:[JFITheme sharedTheme].menuBackgroundColor];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
