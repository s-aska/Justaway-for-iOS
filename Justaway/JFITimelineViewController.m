#import "JFIAppDelegate.h"
#import "JFITimelineViewController.h"
#import "JFIStatusCell.h"
#import "ISDiskCache.h"
#import "ISMemoryCache.h"

NSString *const JFI_Timeline_CellId = @"Cell";
NSString *const JFI_Timeline_CellForHeightId = @"CellForHeight";

@interface JFITimelineViewController ()

@end

@implementation JFITimelineViewController

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
	// Do any additional setup after loading the view, typically from a nib.
    
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    
    NSLog(@"[JFITimelineViewController] viewDidLoad accounts:%lu", (unsigned long)[delegate.accounts count]);
    
    self.operationQueue = NSOperationQueue.new;
    
    // xibファイル名を指定しUINibオブジェクトを生成する
    UINib *nib = [UINib nibWithNibName:@"JFIStatusCell" bundle:nil];
    
    // UITableView#registerNib:forCellReuseIdentifierで、使用するセルを登録
    [_tableView registerNib:nib forCellReuseIdentifier:JFI_Timeline_CellId];
    
    // 高さの計算用のセルを登録
    [_tableView registerNib:nib forCellReuseIdentifier:JFI_Timeline_CellForHeightId];
    
    _tableView.dataSource = self;
    _tableView.delegate = self;
    
    // セルの高さ計算用のオブジェクトをあらかじめ生成して変数に保持しておく
    _cellForHeight = [_tableView dequeueReusableCellWithIdentifier:JFI_Timeline_CellForHeightId];
    
    
    // pull down to refresh
    _refreshControl = UIRefreshControl.new;
    [_refreshControl addTarget:self action:@selector(onRefresh) forControlEvents:UIControlEventValueChanged];
    [_tableView addSubview:_refreshControl];
    
    if ([delegate.accounts count] > 0) {
        [self onRefresh];
    } else {
        // レイアウト確認用のダミーデータ
        NSDictionary *status1 = @{
                                  @"user.name": @"Shinichiro Aska",
                                  @"user.screen_name": @"su_aska",
                                  @"text": @"今日は鯖味噌の日。\n今日は鯖味噌の日。\n今日は鯖味噌の日。",
                                  @"source": @"web",
                                  @"created_at": @"Wed Jun 06 20:07:10 +0000 2012",
                                  @"user.profile_image_url": @"http://pbs.twimg.com/profile_images/435048335674580992/k2F3sHO2_normal.png"
                                  };
        
        NSDictionary *status2 = @{
                                  @"user.name": @"Shinichiro Aska",
                                  @"user.screen_name": @"su_aska",
                                  @"text": @"今日は鯖味噌の日。\n今日は鯖味噌の日。",
                                  @"source": @"StS",
                                  @"created_at": @"Wed Jun 06 20:07:10 +0000 2012",
                                  @"user.profile_image_url": @"http://pbs.twimg.com/profile_images/435048335674580992/k2F3sHO2_normal.png"
                                  };
        
        NSDictionary *status3 = @{
                                  @"user.name": @"Shinichiro Aska",
                                  @"user.screen_name": @"su_aska",
                                  @"text": @"今日は鯖味噌の日。",
                                  @"source": @"<a href=\"http://justaway.info\" rel=\"nofollow\">Justaway for iOS</a>",
                                  @"created_at": @"Wed Jun 06 20:07:10 +0000 2012",
                                  @"user.profile_image_url": @"http://pbs.twimg.com/profile_images/435048335674580992/k2F3sHO2_normal.png"
                                  };
        
        self.statuses = [NSMutableArray array];
        [self.statuses addObjectsFromArray:@[status1, status2, status3]];
        [_tableView reloadData];
    }
    
    if (delegate.enableStreaming) {
        [self startStreaming];
    }
}

- (void)startStreaming
{
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    
    if ([delegate.accounts count] == 0) {
        return;
    }
    
    STTwitterAPI *twitter = [delegate getTwitter];
    self.streamingRequest = [twitter getUserStreamDelimited:nil
                                              stallWarnings:nil
                        includeMessagesFromFollowedAccounts:nil
                                             includeReplies:nil
                                            keywordsToTrack:nil
                                      locationBoundingBoxes:nil
                                              progressBlock:^(id response) {
                                                  if ([response valueForKey:@"text"]) {
                                                      NSDictionary *status = @{
                                                                               @"user.name": [response valueForKeyPath:@"user.name"],
                                                                               @"user.screen_name": [response valueForKeyPath:@"user.screen_name"],
                                                                               @"text": [response valueForKey:@"text"],
                                                                               @"source": [response valueForKey:@"source"],
                                                                               @"created_at": [response valueForKey:@"created_at"],
                                                                               @"user.profile_image_url": [response valueForKeyPath:@"user.profile_image_url"]
                                                                               };
                                                      // 先頭に追加
                                                      [self.statuses insertObject:status atIndex:0];
                                                      [self.tableView reloadData];
                                                  }
                                              } stallWarningBlock:nil
                                                 errorBlock:^(NSError *error) {
                                                     NSLog(@"-- error: %@", [error localizedDescription]);
                                                     UIAlertView *alert = [[UIAlertView alloc]
                                                                           initWithTitle:@"disconnect"
                                                                           message:[error localizedDescription]
                                                                           delegate:nil
                                                                           cancelButtonTitle:nil
                                                                           otherButtonTitles:@"OK", nil
                                                                           ];
                                                     [alert show];
                                                     if([[error domain] isEqualToString:NSURLErrorDomain] && [error code] == NSURLErrorNetworkConnectionLost) {
                                                         // TODO: 失敗回数に応じて間隔を広げながら再接続処理する
                                                     }
                                                 }];
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
    NSLog(@"-- cellForRowAtIndexPath %@", indexPath);
    JFIStatusCell *cell = [tableView dequeueReusableCellWithIdentifier:JFI_Timeline_CellId forIndexPath:indexPath];
    
    NSDictionary *status = [self.statuses objectAtIndex:indexPath.row];
    
    NSURL *url = [NSURL URLWithString:[status valueForKeyPath:@"user.profile_image_url"]];
    
    [cell setLabelTexts:status];
    
    [cell.displayNameLabel sizeToFit];
    
    ISMemoryCache *memCache = [ISMemoryCache sharedCache];
    ISDiskCache *diskCache = [ISDiskCache sharedCache];
    
    cell.iconImageView.image = [memCache objectForKey:url];
    
    if (cell.iconImageView.image == nil) {
        
        if ([diskCache hasObjectForKey:url]) {
            NSLog(@"-- from disk %@", url);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                UIImage *image = [diskCache objectForKey:url];
                dispatch_async(dispatch_get_main_queue(), ^{
                    JFIStatusCell *cell = (id)[tableView cellForRowAtIndexPath:indexPath];
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
                                                   JFIStatusCell *cell = (id)[tableView cellForRowAtIndexPath:indexPath];
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

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    _cellForHeight.frame = _tableView.bounds;
    
    // これでもよいが、上記の方が記述が楽。高さは自動計算するので、ここでは適当で良い。
    // _cellForHeight.frame = CGRectMake(0, 0, _tableView.bounds.size.width, 0);
    
    // indexPathに応じた文字列を設定
    [_cellForHeight setLabelTexts:[self.statuses objectAtIndex:indexPath.row]];
    [_cellForHeight.contentView setNeedsLayout];
    [_cellForHeight.contentView layoutIfNeeded];
    
    // 適切なサイズをAuto Layoutによって自動計算する
    CGSize size = [_cellForHeight.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    
    NSLog(@"-- heightForRowAtIndexPath height:%f", size.height);
    NSLog(@"-- heightForRowAtIndexPath width:%f", size.width);
    
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
    
    if ([delegate.accounts count]  == 0) {
        [_refreshControl endRefreshing];
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
    
    [_refreshControl beginRefreshing];
    
    STTwitterAPI *twitter = [delegate getTwitter];
    [twitter getHomeTimelineSinceID:nil
                              count:20
                       successBlock:^(NSArray *statuses) {
                           self.statuses = [NSMutableArray array];
                           [self.statuses addObjectsFromArray:statuses];
                           [self.tableView reloadData];
                           [_refreshControl endRefreshing];
                       } errorBlock:^(NSError *error) {
                           NSLog(@"-- error: %@", [error localizedDescription]);
                           [_refreshControl endRefreshing];
                       }];
}

@end
