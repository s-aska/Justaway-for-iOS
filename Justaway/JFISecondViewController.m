#import "JFIAppDelegate.h"
#import "JFISecondViewController.h"

@interface JFISecondViewController ()

@end

@implementation JFISecondViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    
    // 通知センターにオブザーバ（通知を受け取るオブジェクト）を追加
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveLoadAccounts:)
                                                 name:@"loadAccounts"
                                               object:delegate];
    
    self.accountsPickerView.delegate = self;
    
    // 背景をタップしたら、キーボードを隠す
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeSoftKeyboard)];
    [self.view addGestureRecognizer:gestureRecognizer];
    
    // 投稿欄に枠をつける
    self.statusTextField.layer.borderWidth = 1;
    self.statusTextField.layer.borderColor = [[UIColor blackColor] CGColor];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)finalize
{
    // 通知の登録を解除
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super finalize];
}

// アカウント追加アクション
- (IBAction)loginInSafariAction:(id)sender
{
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    [delegate postTokenRequest];
}

// アカウント情報全削除アクション
- (IBAction)clearAction:(id)sender
{
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    [delegate clearAccounts];
    [_accountsPickerView reloadAllComponents];
}

// 投稿アクション
- (IBAction)postAction:(id)sender {
    
    NSInteger selectedRow = [_accountsPickerView selectedRowInComponent:0];
    
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    
    STTwitterAPI *twitter = [delegate getTwitterByIndex:&selectedRow];
    
    [twitter postStatusUpdate:[_statusTextField text]
            inReplyToStatusID:nil
                     latitude:nil
                    longitude:nil
                      placeID:nil
           displayCoordinates:nil
                     trimUser:nil
                 successBlock:^(NSDictionary *status) {
                     // ...
                 } errorBlock:^(NSError *error) {
                     // ...
                 }];
}

// アカウント情報がリセットされたらピッカーもリロードする
- (void)receiveLoadAccounts:(NSNotification *)center
{
    [self.accountsPickerView reloadAllComponents];
}

// ピッカーの列数は1固定
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)accountsPickerView
{
    return 1;
}

// ピッカーの行数はアカウント数
- (NSInteger)pickerView:(UIPickerView *)accountsPickerView numberOfRowsInComponent :(NSInteger)component
{
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    return (unsigned long)[delegate.accounts count];
}

// ピッカーのラベルはscreen_name
- (NSString *)pickerView:(UIPickerView *)accountsPickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    NSDictionary *account = [delegate.accounts objectAtIndex:row];
    return [account objectForKey:@"screenName"];
}

// キーボードを隠す処理
- (void)closeSoftKeyboard {
    [self.view endEditing:YES];
}

@end
