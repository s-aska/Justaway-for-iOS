#import "JFIProfileViewController.h"
#import "JFIHTTPImageOperation.h"

@interface JFIProfileViewController ()

@end

@implementation JFIProfileViewController

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSLog(@"[%@] %s", NSStringFromClass([self class]), sel_getName(_cmd));
    
    self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    
    [JFIHTTPImageOperation loadURL:[[NSURL alloc] initWithString:@"https://pbs.twimg.com/profile_banners/168405005/1402934681"]
                       processType:ImageProcessTypeNone
                           handler:^(NSHTTPURLResponse *response, UIImage *image, NSError *error) {
                               self.backgroundImageView.image = image;
                           }];
    
    [JFIHTTPImageOperation loadURL:[[NSURL alloc] initWithString:@"https://pbs.twimg.com/profile_images/378800000383509765/32c1dba484eb35e1d1c904e4ea729541.png"]
                       processType:ImageProcessTypeIcon64
                           handler:^(NSHTTPURLResponse *response, UIImage *image, NSError *error) {
                               self.iconImageView.image = image;
                           }];
}

- (IBAction)closeAction:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
