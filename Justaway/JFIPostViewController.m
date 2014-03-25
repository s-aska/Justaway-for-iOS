#import "JFIAppDelegate.h"
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
    
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    if ([delegate.accounts count] > 0) {
        [self.statusTextField becomeFirstResponder];
    } else {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"disconnect"
                              message:@"「認」ボタンからアカウントを追加して下さい。"
                              delegate:nil
                              cancelButtonTitle:nil
                              otherButtonTitles:@"OK", nil
                              ];
        [alert show];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Action

- (IBAction)backAction:(id)sender
{
    NSLog(@"[JFIPostViewController] backAction");
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)postAction:(id)sender
{
    NSLog(@"[JFIPostViewController] postAction");
    // TODO: 入力チェック
    
    // 投稿処理
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    
    // TODO: getCurrentTwitter
    NSInteger index = 0;
    STTwitterAPI *twitter = [delegate getTwitterByIndex:&index];
    
    [twitter postStatusUpdate:[_statusTextField text]
            inReplyToStatusID:nil
                     latitude:nil
                    longitude:nil
                      placeID:nil
           displayCoordinates:nil
                     trimUser:nil
                 successBlock:^(NSDictionary *status) {
                     [self.navigationController popViewControllerAnimated:YES];
                 } errorBlock:^(NSError *error) {
                     NSLog(@"-- %@", [error localizedDescription]);
                 }];
}

@end
