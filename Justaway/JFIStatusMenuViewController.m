#import "JFIStatusMenuViewController.h"
#import "JFITheme.h"

@interface JFIStatusMenuViewController ()

@end

@implementation JFIStatusMenuViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    JFITheme *theme = [JFITheme sharedTheme];
    [self.tableView setSeparatorColor:theme.mainHighlightBackgroundColor];
    self.view.backgroundColor = theme.mainBackgroundColor;
    [self.titleLabel setTextColor:theme.titleTextColor];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)closeAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
