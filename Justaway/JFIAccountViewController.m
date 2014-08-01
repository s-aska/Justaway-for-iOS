#import "JFIConstants.h"
#import "JFIAppDelegate.h"
#import "JFIAccountViewController.h"
#import "JFIAccountCell.h"
#import "JFIAccount.h"
#import "JFIHTTPImageOperation.h"
#import "JFITheme.h"

@interface JFIAccountViewController ()

@property (nonatomic) NSMutableArray *accounts;

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
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
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
    
    [self loadAccounts];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.accounts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JFIAccountCell *cell = [tableView dequeueReusableCellWithIdentifier:JFICellID forIndexPath:indexPath];
    
    JFIAccount *account = [self.accounts objectAtIndex:indexPath.row];
    
    [cell setLabelTexts:account];
    
    [JFIHTTPImageOperation loadURL:account.profileImageBiggerURL
                       processType:ImageProcessTypeIcon
                           handler:^(NSHTTPURLResponse *response, UIImage *image, NSError *error) {
                               JFIAccountCell *cell = (JFIAccountCell *)[tableView cellForRowAtIndexPath:indexPath];
                               cell.iconImageView.image = image;
                           }];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.accounts removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    if (destinationIndexPath.row < self.accounts.count) {
        JFIAccount *account = [self.accounts objectAtIndex:sourceIndexPath.row];
        [self.accounts removeObjectAtIndex:sourceIndexPath.row];
        [self.accounts insertObject:account atIndex:destinationIndexPath.row];
    }
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
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    self.accounts = [delegate.accounts mutableCopy];
    for (JFIAccount *account in self.accounts) {
        NSLog(@"[%@] %s %@:%@", NSStringFromClass([self class]), sel_getName(_cmd), account.screenName, account.priority);
    }
    [self.tableView reloadData];
}

#pragma mark - Action

- (IBAction)editAction:(id)sender
{
    [self.tableView setEditing:!self.tableView.editing animated:YES];
    if (self.tableView.editing) {
        [self.rightButton setTitle:@"Done" forState:UIControlStateNormal];
    } else {
        [self.rightButton setTitle:@"Edit" forState:UIControlStateNormal];
        JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
        NSMutableDictionary *accountMap = NSMutableDictionary.new;
        int priority = 0;
        for (JFIAccount *account in self.accounts) {
            [delegate updateAccount:account.userID
                         screenName:account.screenName
                               name:account.displayName
                    profileImageURL:account.profileImageURL
                           priority:@(priority)];
            [accountMap setObject:account.userID forKey:account.userID];
            priority++;
        }
        for (JFIAccount *account in delegate.accounts) {
            if (![accountMap objectForKey:account.userID]) {
                [delegate removeAccount:account.userID];
            }
        }
        [delegate loadAccounts];
    }
}

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
