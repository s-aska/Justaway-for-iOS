#import "JFIPostViewController.h"

@interface JFIPostViewController ()

@end

@implementation JFIPostViewController

- (id)initWithCoder:(NSCoder*)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        // Custom initialization
        NSLog(@"[JFIPostViewController] initWithCoder");
        self.title = @"Post";
        UIBarButtonItem *button = [[UIBarButtonItem alloc]
                                   initWithTitle:@"投稿"
                                   style:UIBarButtonItemStyleBordered
                                   target:self
                                   action:@selector(postAction:)];
        self.navigationItem.rightBarButtonItem = button;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSLog(@"[JFIPostViewController] viewDidLoad");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Action

- (IBAction)backAction:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
    NSLog(@"[JFIPostViewController] backAction");
}

- (IBAction)postAction:(id)sender
{
    // 入力チェック
    // 投稿処理
    [self.navigationController popViewControllerAnimated:YES];
    NSLog(@"[JFIPostViewController] postAction");
}

@end
