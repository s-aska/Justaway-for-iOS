#import "JFIConstants.h"
#import "JFIAppDelegate.h"
#import "JFITabViewController.h"

@interface JFITabViewController ()

@property (nonatomic) BOOL scrolling;

@end

@implementation JFITabViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil tabType:(TabType)tabType
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.stacks = [@[] mutableCopy];
        self.tabType = tabType;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveStatus:)
                                                 name:JFIReceiveStatusNotification
                                               object:delegate];
    
    NSLog(@"[JFIHomeViewController] viewDidLoad accounts:%lu", (unsigned long)[delegate.accounts count]);
    
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
    [self.tableView insertSubview:self.refreshControl atIndex:0];
    
    if ([delegate.accounts count] > 0) {
        [self onRefresh];
    } else if (self.tabType == TabTypeHome) {
        // レイアウト確認用のダミーデータ
        NSDictionary *status1 = @{@"user.name": @"Shinichiro Aska",
                                  @"user.screen_name": @"su_aska",
                                  @"text": @"今日は鯖味噌の日。\n今日は鯖味噌の日。\n今日は鯖味噌の日。",
                                  @"source": @"web",
                                  @"created_at": @"Wed Jun 06 20:07:10 +0000 2012",
                                  @"user.profile_image_url": @"https://pbs.twimg.com/profile_images/450683047495471105/2Qq3AXYv_bigger.png",
                                  @"retweet_count": @10000,
                                  @"favorite_count": @20000};
        
        NSDictionary *status2 = @{@"user.name": @"Shinichiro Aska",
                                  @"user.screen_name": @"su_aska",
                                  @"text": @"今日は鯖味噌の日。\n今日は鯖味噌の日。",
                                  @"source": @"StS",
                                  @"created_at": @"Wed Jun 06 20:07:10 +0000 2012",
                                  @"user.profile_image_url": @"https://pbs.twimg.com/profile_images/450683047495471105/2Qq3AXYv_bigger.png",
                                  @"retweet_count": @100,
                                  @"favorite_count": @200};
        
        NSDictionary *status3 = @{@"user.name": @"Shinichiro Aska",
                                  @"user.screen_name": @"su_aska",
                                  @"text": @"今日は鯖味噌の日。",
                                  @"source": @"<a href=\"http://justaway.info\" rel=\"nofollow\">Justaway for iOS</a>",
                                  @"created_at": @"Wed Jun 06 20:07:10 +0000 2012",
                                  @"user.profile_image_url": @"https://pbs.twimg.com/profile_images/450683047495471105/2Qq3AXYv_bigger.png",
                                  @"retweet_count": @0,
                                  @"favorite_count": @0};
        
        self.statuses = [NSMutableArray array];
        [self.statuses addObject:[status1 mutableCopy]];
        [self.statuses addObject:[status2 mutableCopy]];
        [self.statuses addObject:[status3 mutableCopy]];
        [self.tableView reloadData];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.statuses count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JFIStatusCell *cell = [tableView dequeueReusableCellWithIdentifier:JFICellID forIndexPath:indexPath];
    
    NSDictionary *status = [self.statuses objectAtIndex:indexPath.row];
    
    if (cell.status == status) {
        return cell;
    }
    
    [cell setLabelTexts:status];
    
    [cell.displayNameLabel sizeToFit];
    
    [cell loadImages:self.scrolling];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *status = [self.statuses objectAtIndex:indexPath.row];
    if (status == nil) {
        return 0;
    }
    
    // 高さの計算結果をキャッシュから参照
    NSNumber *height = [status objectForKey:@"height"];
    if (height != nil) {
        return [height floatValue] + 2;
    }
    
    self.cellForHeight.frame = self.tableView.bounds;
    
    [self.cellForHeight setLabelTexts:status];
    [self.cellForHeight.contentView setNeedsLayout];
    [self.cellForHeight.contentView layoutIfNeeded];
    
    // 適切なサイズをAuto Layoutによって自動計算する
    CGSize size = [self.cellForHeight.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    
    // 高さの計算結果をキャッシュ
    [status setObject:@(size.height) forKey:@"height"];
    
    // 自動計算で得られた高さを返す
    return size.height + 2;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Statusを選択された時の処理
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    NSLog(@"scrollViewWillBeginDragging");
    self.scrolling = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(finalize) object:nil];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSLog(@"scrollViewDidEndDecelerating");
    [self finalizeWithDebounce:.5f];
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
    
    switch (self.tabType) {
        case TabTypeHome:
            [self loadHome:twitter];
            break;
            
        case TabTypeNotifications:
            [self loadNotifications:twitter];
            break;
            
        case TabTypeMessages:
            [self loadMessages:twitter];
            break;
            
        case TabTypeUserList:
            
            break;
            
        default:
            break;
    }
}

#pragma mark - NSNotificationCenter handler

- (void)receiveStatus:(NSNotification *)center
{
    NSDictionary *status = center.userInfo;
    [self.stacks addObject:status];
    
    NSLog(@"receiveStatus stack count:%lu", (unsigned long)[self.stacks count]);
    
    if (!self.scrolling) {
        [self finalizeWithDebounce:.5f];
    }
}

#pragma mark -

/*
 * イベントの発火に合わせてゴリゴリUIブロックするとAnimationが突っかかったりするのでdebounceする
 * 今はおよそスクロール終了やストリーミング受信（非スクロール時）に0.5秒delayでレンダリング処理を仕込んでいる
 */
- (void)finalizeWithDebounce:(CGFloat)delay
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(finalize) object:nil];
    [self performSelector:@selector(finalize) withObject:nil afterDelay:delay];
}

- (void)finalize
{
    NSLog(@"finalize stack count:%lu", (unsigned long)[self.stacks count]);
    
    self.scrolling = NO;
    
    // スタック内容をレンダリングする
    if ([self.stacks count] > 0) {
        
        NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
        int index = 0;
        for (NSDictionary *status in self.stacks) {
            [self.statuses insertObject:[status mutableCopy] atIndex:0];
            [indexPaths addObject:[NSIndexPath indexPathForRow:index inSection:0]];
            index++;
        }
        
        if (self.tableView.contentOffset.y > 0 && [self.tableView.visibleCells count] > 0) {
            // スクロール状態では画面を動かさずに追加
            UITableViewCell *lastCell = [self.tableView.visibleCells lastObject];
            CGFloat offset = lastCell.frame.origin.y - self.tableView.contentOffset.y;
            [UIView setAnimationsEnabled:NO];
            [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
            [self.tableView setContentOffset:CGPointMake(0.0, lastCell.frame.origin.y - offset) animated:NO];
            [UIView setAnimationsEnabled:YES];
        } else {
            // スクロール位置が最上位の場合はアニメーションしながら追加
            [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationBottom];
        }
        
        self.stacks = [@[] mutableCopy];
    }
    
    for (JFIStatusCell *cell in self.tableView.visibleCells) {
        if (cell.iconImageView.image == nil) {
            [cell loadImages:NO];
        }
    }
}

- (void)loadHome:(STTwitterAPI *)twitter
{
    //    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    [twitter getHomeTimelineSinceID:nil
                              count:20
                       successBlock:^(NSArray *statuses) {
                           self.statuses = [NSMutableArray array];
                           for (NSDictionary *dictionaly in statuses) {
                               [self.statuses addObject:[dictionaly mutableCopy]];
                           }
                           [self.tableView reloadData];
                           [self.refreshControl endRefreshing];
                           //                           [delegate startStreaming];
                       } errorBlock:^(NSError *error) {
                           NSLog(@"-- error: %@", [error localizedDescription]);
                           [self.refreshControl endRefreshing];
                       }];
}

- (void)loadNotifications:(STTwitterAPI *)twitter
{
    // JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    [twitter getMentionsTimelineSinceID:nil
                                  count:20
                           successBlock:^(NSArray *statuses) {
                               self.statuses = [NSMutableArray array];
                               for (NSDictionary *dictionaly in statuses) {
                                   [self.statuses addObject:[dictionaly mutableCopy]];
                               }
                               [self.tableView reloadData];
                               [self.refreshControl endRefreshing];
                           } errorBlock:^(NSError *error) {
                               NSLog(@"-- error: %@", [error localizedDescription]);
                               [self.refreshControl endRefreshing];
                           }];
    
}

- (void)loadMessages:(STTwitterAPI *)twitter
{
    // エラー処理
    void(^errorBlock)(NSError *) =
    ^(NSError *error) {
        NSLog(@"-- error: %@", [error localizedDescription]);
        [self.refreshControl endRefreshing];
    };
    
    /*
     * ネストを深くしたくないが為に実行順と記述順が逆になるな書き方をしてしまった
     */
    NSMutableArray *receivedRows = [NSMutableArray array];
    
    // (3) 送信したDM一覧取得後の処理
    void(^sentSuccessBlock)(NSArray *) =
    ^(NSArray *messages) {
        
        // 受信したDM一覧と送信したDM一覧を混ぜて並び替える
        [receivedRows addObjectsFromArray:messages];
        NSSortDescriptor *sortDispNo = [[NSSortDescriptor alloc] initWithKey:@"created_at" ascending:NO];
        NSArray *sortDescArray = [NSArray arrayWithObjects:sortDispNo, nil];
        NSArray *statuses = [[receivedRows sortedArrayUsingDescriptors:sortDescArray] mutableCopy];
        self.statuses = [NSMutableArray array];
        for (NSDictionary *dictionaly in statuses) {
            NSDictionary *status = @{@"id_str": [dictionaly valueForKey:@"id_str"],
                                     @"user.name": [dictionaly valueForKeyPath:@"sender.name"],
                                     @"user.screen_name": [dictionaly valueForKeyPath:@"sender.screen_name"],
                                     @"text": [dictionaly valueForKey:@"text"],
                                     @"source": @"",
                                     @"created_at": [dictionaly valueForKey:@"created_at"],
                                     @"user.profile_image_url": [dictionaly valueForKeyPath:@"sender.profile_image_url"],
                                     @"retweet_count": @0,
                                     @"favorite_count": @0};
            [self.statuses addObject:[status mutableCopy]];
        }
        [self.tableView reloadData];
        [self.refreshControl endRefreshing];
    };
    
    // (2) 受信したDM一覧取得後の処理
    void(^receiveSuccessBlock)(NSArray *) =
    ^(NSArray *messages) {
        [receivedRows addObjectsFromArray:messages];
        [twitter getDirectMessagesSinceID:nil
                                    maxID:nil
                                    count:nil
                                     page:nil
                          includeEntities:0
                             successBlock:sentSuccessBlock
                               errorBlock:errorBlock];
        
    };
    
    // (1) 受信したDM一覧取得
    [twitter getDirectMessagesSinceID:nil
                                count:20
                         successBlock:receiveSuccessBlock
                           errorBlock:errorBlock];
}

@end
