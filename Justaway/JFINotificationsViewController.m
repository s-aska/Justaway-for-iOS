#import "JFIConstants.h"
#import "JFIAppDelegate.h"
#import "JFINotificationsViewController.h"
#import "JFIHTTPImageOperation.h"

@interface JFINotificationsViewController ()

@end

@implementation JFINotificationsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    
    // xibファイル名を指定しUINibオブジェクトを生成する
    UINib *nib = [UINib nibWithNibName:@"JFIStatusCell" bundle:nil];
    
    // UITableView#registerNib:forCellReuseIdentifierで、使用するセルを登録
    [self.tableView registerNib:nib forCellReuseIdentifier:JFICellID];
    
    // 高さの計算用のセルを登録
    [self.tableView registerNib:nib forCellReuseIdentifier:JFICellForHeightID];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    // セルの高さ計算用のオブジェクトをあらかじめ生成して変数に保持しておく
    self.cellForHeight = [self.tableView dequeueReusableCellWithIdentifier:JFICellForHeightID];
    
    // pull down to refresh
    self.refreshControl = UIRefreshControl.new;
    [self.refreshControl addTarget:self action:@selector(onRefresh) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
    if ([delegate.accounts count] > 0) {
        [self onRefresh];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.statuses count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //    NSLog(@"-- cellForRowAtIndexPath %@", indexPath);
    JFIStatusCell *cell = [tableView dequeueReusableCellWithIdentifier:JFICellID forIndexPath:indexPath];
    
    NSDictionary *status = [self.statuses objectAtIndex:indexPath.row];
    
    NSURL *url = [NSURL URLWithString:[status valueForKeyPath:@"user.profile_image_url"]];
    
    [cell setLabelTexts:status];
    
    [cell.displayNameLabel sizeToFit];
    
    [JFIHTTPImageOperation loadURL:url
                           handler:^(NSHTTPURLResponse *response, UIImage *image, NSError *error) {
                               JFIStatusCell *cell = (JFIStatusCell *)[tableView cellForRowAtIndexPath:indexPath];
                               cell.iconImageView.image = image;
                           }];
    
    return cell;
}

#pragma mark - UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.cellForHeight.frame = self.tableView.bounds;
    
    [self.cellForHeight setLabelTexts:[self.statuses objectAtIndex:indexPath.row]];
    [self.cellForHeight.contentView setNeedsLayout];
    [self.cellForHeight.contentView layoutIfNeeded];
    
    // 適切なサイズをAuto Layoutによって自動計算する
    CGSize size = [self.cellForHeight.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    
    // 自動計算で得られた高さを返す
    return size.height;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Statusを選択された時の処理
}

#pragma mark - UIRefreshControl

- (void)onRefresh
{
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    
    if ([delegate.accounts count] == 0) {
        [self.refreshControl endRefreshing];
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"disconnect"
                              message:@"「認」ボタンからアカウントを追加して下さい。"
                              delegate:nil
                              cancelButtonTitle:nil
                              otherButtonTitles:@"OK", nil
                              ];
        [alert show];
        return;
    }
    
    [self.refreshControl beginRefreshing];
    
    STTwitterAPI *twitter = [delegate getTwitter];
    [twitter getMentionsTimelineSinceID:nil
                                  count:20
                           successBlock:^(NSArray *statuses) {
                               self.statuses = [NSMutableArray array];
                               [self.statuses addObjectsFromArray:statuses];
                               [self.tableView reloadData];
                               [self.refreshControl endRefreshing];
                           } errorBlock:^(NSError *error) {
                               NSLog(@"-- error: %@", [error localizedDescription]);
                               [self.refreshControl endRefreshing];
                           }];
}

@end
