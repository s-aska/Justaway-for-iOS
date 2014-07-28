#import "JFIConstants.h"
#import "JFIAppDelegate.h"
#import "JFIAccountViewController.h"
#import "JFIAccountCell.h"
#import "JFIAccount.h"
#import "JFIHTTPImageOperation.h"
#import "JFITheme.h"

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
    
    JFITheme *theme = [JFITheme sharedTheme];
    [self.tableView setSeparatorColor:theme.mainHighlightBackgroundColor];
    self.view.backgroundColor = theme.mainBackgroundColor;
    [self.titleLabel setTextColor:theme.titleTextColor];
    
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    
    // アカウントが追加されたらリロードする
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveAccessToken:)
                                                 name:JFIReceiveAccessTokenNotification
                                               object:delegate];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadAccounts)
                                                 name:JFIRefreshAccessTokenNotification
                                               object:delegate];
    
    // xibファイル名を指定しUINibオブジェクトを生成する
    UINib *nib = [UINib nibWithNibName:@"JFIAccountCell" bundle:nil];
    
    // UITableView#registerNib:forCellReuseIdentifierで、使用するセルを登録
    [self.tableView registerNib:nib forCellReuseIdentifier:JFICellID];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    // 起動後1回だけリロードする
    if (!delegate.refreshedAccounts) {
        [delegate refreshAccounts];
    }
    
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
    
    [cell setLabelTexts:account];
    
    //    [cell.displayNameLabel sizeToFit];
    
    [JFIHTTPImageOperation loadURL:account.profileImageBiggerURL
                       processType:ImageProcessTypeIcon
                           handler:^(NSHTTPURLResponse *response, UIImage *image, NSError *error) {
                               JFIAccountCell *cell = (JFIAccountCell *)[tableView cellForRowAtIndexPath:indexPath];
                               cell.iconImageView.image = image;
                           }];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 56;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"[JFIAccountViewController] didSelectRowAtIndexPath");
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    delegate.currentAccountIndex = indexPath.row;
    if (delegate.streamingMode) {
        [delegate restartStreaming];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:JFISelectAccessTokenNotification
                                                        object:[[UIApplication sharedApplication] delegate]
                                                      userInfo:nil];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Observer

- (void)receiveAccessToken:(NSNotification *)center
{
    // TODO: 「◯◯さんこんにちわ！！！！１１」的な
    NSLog(@"[JFIAccountViewController] receiveAccessToken");
    [self loadAccounts];
    [self closeAction:nil];
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
