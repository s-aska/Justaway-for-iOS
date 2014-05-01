#import "JFIConstants.h"
#import "JFIEntity.h"
#import "JFIAppDelegate.h"
#import "JFITabViewController.h"

@interface JFITabViewController ()

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
    
    switch (self.tabType) {
        case TabTypeHome:
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(receiveStatus:)
                                                         name:JFIReceiveStatusNotification
                                                       object:delegate];
            break;
        case TabTypeNotifications:
            break;
        case TabTypeMessages:
            break;
        case TabTypeUserList:
            break;
            
        default:
            break;
    }
    
    NSLog(@"[JFIHomeViewController] viewDidLoad accounts:%lu", (unsigned long)[delegate.accounts count]);
    
    // xibファイル名を指定しUINibオブジェクトを生成する
    UINib *nib = [UINib nibWithNibName:@"JFIEntityCell" bundle:nil];
    
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
        NSDictionary *status1 = @{@"id_str": @"1",
                                  @"user.name": @"Shinichiro Aska",
                                  @"user.screen_name": @"su_aska",
                                  @"text": @"今日は鯖味噌の日。\n今日は鯖味噌の日。\n今日は鯖味噌の日。",
                                  @"source": @"web",
                                  @"created_at": @"Wed Jun 06 20:07:10 +0000 2012",
                                  @"user.profile_image_url": @"https://pbs.twimg.com/profile_images/450683047495471105/2Qq3AXYv_bigger.png",
                                  @"retweet_count": @10000,
                                  @"favorite_count": @20000};
        
        NSDictionary *status2 = @{@"id_str": @"2",
                                  @"user.name": @"Shinichiro Aska",
                                  @"user.screen_name": @"su_aska",
                                  @"text": @"今日は鯖味噌の日。\n今日は鯖味噌の日。",
                                  @"source": @"StS",
                                  @"created_at": @"Wed Jun 06 20:07:10 +0000 2012",
                                  @"user.profile_image_url": @"https://pbs.twimg.com/profile_images/450683047495471105/2Qq3AXYv_bigger.png",
                                  @"retweet_count": @100,
                                  @"favorite_count": @200};
        
        NSDictionary *status3 = @{@"id_str": @"3",
                                  @"user.name": @"Shinichiro Aska",
                                  @"user.screen_name": @"su_aska",
                                  @"text": @"今日は鯖味噌の日。",
                                  @"source": @"<a href=\"http://justaway.info\" rel=\"nofollow\">Justaway for iOS</a>",
                                  @"created_at": @"Wed Jun 06 20:07:10 +0000 2012",
                                  @"user.profile_image_url": @"https://pbs.twimg.com/profile_images/450683047495471105/2Qq3AXYv_bigger.png",
                                  @"retweet_count": @0,
                                  @"favorite_count": @0};
        
        self.entities = [NSMutableArray array];
        [self.entities addObject:[[JFIEntity alloc] initWithStatus:status1]];
        [self.entities addObject:[[JFIEntity alloc] initWithStatus:status2]];
        [self.entities addObject:[[JFIEntity alloc] initWithStatus:status3]];
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
    return [self.entities count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JFIEntityCell *cell = [tableView dequeueReusableCellWithIdentifier:JFICellID forIndexPath:indexPath];
    
    JFIEntity *tweet = [self.entities objectAtIndex:indexPath.row];
    
    if (cell.entity == tweet) {
        return cell;
    }
    
    [cell setLabelTexts:tweet];
    
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
    JFIEntity *entity = [self.entities objectAtIndex:indexPath.row];
    if (entity == nil) {
        return 0;
    }
    
    // 高さの計算結果をキャッシュから参照
    if (entity.height != nil) {
        return [entity.height floatValue] + 2;
    }
    
    self.cellForHeight.frame = self.tableView.bounds;
    
    [self.cellForHeight setLabelTexts:entity];
    [self.cellForHeight.contentView setNeedsLayout];
    [self.cellForHeight.contentView layoutIfNeeded];
    
    // 適切なサイズをAuto Layoutによって自動計算する
    CGSize size = [self.cellForHeight.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    
    // 高さの計算結果をキャッシュ
    entity.height = @(size.height);
    
    // 自動計算で得られた高さを返す
    return size.height + 2;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"didSelectRowAtIndexPath");
    JFIEntity *entity = [self.entities objectAtIndex:indexPath.row];
    if (entity == nil) {
        return;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:JFIOpenStatusNotification
                                                        object:[[UIApplication sharedApplication] delegate]
                                                      userInfo:@{@"entity": entity}];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    NSLog(@"scrollViewWillBeginDragging");
    self.scrolling = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(finalize) object:nil];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	if (!decelerate) {
        NSLog(@"scrollViewDidEndDragging");
        [self finalizeWithDebounce:.5f];
	}
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
    
    [self loadEntities];
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
        for (JFIEntity *tweet in self.stacks) {
            [self.entities insertObject:tweet atIndex:0];
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
    
    for (JFIEntityCell *cell in self.tableView.visibleCells) {
        if (cell.iconImageView.image == nil) {
            [cell loadImages:NO];
        }
    }
}

#pragma mark - NSNotificationCenter

- (void)receiveStatus:(NSNotification *)center
{
    JFIEntity *tweet = [center.userInfo valueForKey:@"tweet"];
    [self.stacks addObject:tweet];
    
    NSLog(@"receiveStatus stack count:%lu", (unsigned long)[self.stacks count]);
    
    if (!self.scrolling) {
        [self finalizeWithDebounce:.5f];
    }
}

#pragma mark - JFITabViewController

- (void)loadEntities
{
    [NSException raise:NSInternalInconsistencyException format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}

@end
