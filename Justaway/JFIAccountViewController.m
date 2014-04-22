#import "JFIConstants.h"
#import "JFIAppDelegate.h"
#import "JFIAccountViewController.h"
#import "JFIAccountCell.h"
#import "JFIAccount.h"
#import "JFIHTTPImageOperation.h"

@interface JFIAccountViewController ()

@end

@implementation JFIAccountViewController

#pragma mark - UIViewController

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
    
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    
    // アカウントが追加されたらリロードする
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveAccessToken:)
                                                 name:JFIReceiveAccessTokenNotification
                                               object:delegate];
    
    self.operationQueue = NSOperationQueue.new;
    
    // xibファイル名を指定しUINibオブジェクトを生成する
    UINib *nib = [UINib nibWithNibName:@"JFIAccountCell" bundle:nil];
    
    // UITableView#registerNib:forCellReuseIdentifierで、使用するセルを登録
    [self.tableView registerNib:nib forCellReuseIdentifier:JFICellID];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    [self loadAccounts];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    return [delegate.accounts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    
    //    NSLog(@"[JFIAccountViewController] cellForRowAtIndexPath %@", indexPath);
    
    JFIAccountCell *cell = [tableView dequeueReusableCellWithIdentifier:JFICellID forIndexPath:indexPath];
    
    JFIAccount *account = [delegate.accounts objectAtIndex:indexPath.row];
    
    NSURL *url = [NSURL URLWithString:account.profileImageURL];
    
    [cell setLabelTexts:account];
    
    //    [cell.displayNameLabel sizeToFit];
    
    [JFIHTTPImageOperation loadURL:url
                           handler:^(NSHTTPURLResponse *response, UIImage *image, NSError *error) {
                               JFIAccountCell *cell = (JFIAccountCell *)[tableView cellForRowAtIndexPath:indexPath];
                               cell.iconImageView.image = image;
                           }];
    
    return cell;
}

#pragma mark - UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 47;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 選択された時の処理
}

#pragma mark - Observer

- (void)receiveAccessToken:(NSNotification *)center
{
    // TODO: 「◯◯さんこんにちわ！！！！１１」的な
    NSLog(@"[JFIAccountViewController] receiveAccessToken");
    [self loadAccounts];
}

#pragma mark -

- (void)loadAccounts
{
    [self.tableView reloadData];
}

#pragma mark - Action

- (IBAction)resetAction:(id)sender
{
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    [delegate clearAccounts];
    [self loadAccounts];
}

- (IBAction)loginInSafariAction:(id)sender
{
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    [delegate postTokenRequest];
}

- (IBAction)loginWithiOSAction:(id)sender
{
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    [delegate loginUsingIOSAccount];
}

- (IBAction)closeAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
