#import "JFIAppDelegate.h"
#import "JFIAccountViewController.h"
#import "JFIAccountCell.h"
#import "JFIAccount.h"
#import "ISDiskCache.h"
#import "ISMemoryCache.h"

@interface JFIAccountViewController ()

@end

NSString *const JFI_Account_CellId = @"Cell";

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
                                                 name:@"receiveAccessToken"
                                               object:delegate];

    self.operationQueue = NSOperationQueue.new;

    // xibファイル名を指定しUINibオブジェクトを生成する
    UINib *nib = [UINib nibWithNibName:@"JFIAccountCell" bundle:nil];
    
    // UITableView#registerNib:forCellReuseIdentifierで、使用するセルを登録
    [_tableView registerNib:nib forCellReuseIdentifier:JFI_Account_CellId];
    
    _tableView.dataSource = self;
    _tableView.delegate = self;
    
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
    
    NSLog(@"[JFIAccountViewController] cellForRowAtIndexPath %@", indexPath);
    
    JFIAccountCell *cell = [tableView dequeueReusableCellWithIdentifier:JFI_Account_CellId forIndexPath:indexPath];
    
    JFIAccount *account = [delegate.accounts objectAtIndex:indexPath.row];
    
    NSURL *url = [NSURL URLWithString:account.profileImageUrl];
    
    [cell setLabelTexts:account];
    
//    [cell.displayNameLabel sizeToFit];

    ISMemoryCache *memCache = [ISMemoryCache sharedCache];
    ISDiskCache *diskCache = [ISDiskCache sharedCache];
    
    cell.iconImageView.image = [memCache objectForKey:url];
    
    if (cell.iconImageView.image == nil) {
        
        if ([diskCache hasObjectForKey:url]) {
            NSLog(@"-- from disk %@", url);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                UIImage *image = [diskCache objectForKey:url];
                dispatch_async(dispatch_get_main_queue(), ^{
                    JFIAccountCell *cell = (id)[tableView cellForRowAtIndexPath:indexPath];
                    cell.iconImageView.image = image;
                    [cell setNeedsLayout];
                });
            });
        } else {
            NSLog(@"-- from network %@", url);
            NSURLRequest *request = [NSURLRequest requestWithURL:url];
            [NSURLConnection sendAsynchronousRequest:request
                                               queue:self.operationQueue
                                   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                       UIImage *image = [UIImage imageWithData:data];
                                       if (image) {
                                           [memCache setObject:image forKey:url];
                                           [diskCache setObject:image forKey:url];
                                           dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   JFIAccountCell *cell = (id)[tableView cellForRowAtIndexPath:indexPath];
                                                   cell.iconImageView.image = image;
                                                   [cell setNeedsLayout];
                                               });
                                           });
                                       } else {
                                           NSLog(@"-- sendAsynchronousRequest: fail");
                                       }
                                   }];
        }
    } else {
        NSLog(@"-- from memory %@", url);
    }
    
    return cell;
}

#pragma mark - UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 47;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
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
