#import "JFIMainViewController.h"
#import "JFIPostViewController.h"

@interface JFIMainViewController ()

@end

@implementation JFIMainViewController

- (id)initWithCoder:(NSCoder*)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        // Custom initialization
        NSLog(@"[JFIMainViewController] initWithCoder");
        self.title = @"Main";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSLog(@"[JFIMainViewController] viewDidLoad");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Action

- (IBAction)postAction:(id)sender
{
    NSLog(@"[JFIMainViewController] postAction");
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Post" bundle:nil];
    JFIPostViewController *postViewController = [storyboard instantiateViewControllerWithIdentifier:@"JFIPostViewController"];
    [self.navigationController pushViewController:postViewController animated:YES];
}

- (IBAction)accountAction:(id)sender
{
}

@end
