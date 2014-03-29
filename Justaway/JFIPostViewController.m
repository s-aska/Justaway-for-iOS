#import "JFIAppDelegate.h"
#import "JFIPostViewController.h"

@interface JFIPostViewController ()

@end

@implementation JFIPostViewController

- (id)initWithCoder:(NSCoder*)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        NSLog(@"[JFIPostViewController] initWithCoder");
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 背景をタップしたら、キーボードを隠す
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeSoftKeyboard)];
    [self.view addGestureRecognizer:gestureRecognizer];
    
    // 入力フィールドにフォーカスを当てる
    [self.statusTextField becomeFirstResponder];
    
    // TODO: ツイート数数える奴
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
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
    
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    
    // TODO: マルチアカウント対応
    STTwitterAPI *twitter = [delegate getTwitter];
    
    [twitter postStatusUpdate:[self.statusTextField text]
            inReplyToStatusID:nil
                     latitude:nil
                    longitude:nil
                      placeID:nil
           displayCoordinates:nil
                     trimUser:nil
                 successBlock:^(NSDictionary *status) {
                     [self.navigationController popViewControllerAnimated:YES];
                 } errorBlock:^(NSError *error) {
                     NSLog(@"[JFIPostViewController] postAction error:%@", [error localizedDescription]);
                     [[[UIAlertView alloc]
                       initWithTitle:@"disconnect"
                       message:[error localizedDescription]
                       delegate:nil
                       cancelButtonTitle:nil
                       otherButtonTitles:@"OK", nil
                       ] show];
                 }];
}

#pragma mark -

// キーボードを隠す処理
- (void)closeSoftKeyboard {
    [self.view endEditing:YES];
}

@end
