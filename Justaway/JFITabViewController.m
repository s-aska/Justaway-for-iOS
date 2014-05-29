#import "JFIConstants.h"
#import "JFIEntity.h"
#import "JFIAppDelegate.h"
#import "JFITabViewController.h"

@interface JFITabViewController ()

@end

@implementation JFITabViewController

- (id)initWithType:(TabType)tabType
{
    self = [super init];
    if (self) {
        self.stacks = [@[] mutableCopy];
        self.tabType = tabType;
    }
    return self;
}

- (void)loadView {
	[super loadView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onRefresh)
                                                 name:JFISelectAccessTokenNotification
                                               object:delegate];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onRefresh)
                                                 name:JFIReceiveAccessTokenNotification
                                               object:delegate];
    
    // UIActionSheetが閉じたら選択解除
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(closeStatus:)
                                                 name:JFICloseStatusNotification
                                               object:delegate];
    
    NSLog(@"[JFIHomeViewController] viewDidLoad accounts:%lu", (unsigned long)[delegate.accounts count]);
    
    // xibファイル名を指定しUINibオブジェクトを生成する
    UINib *nib = [UINib nibWithNibName:@"JFIEntityCell" bundle:nil];
    
    // UITableView#registerNib:forCellReuseIdentifierで、使用するセルを登録
    [self.tableView registerNib:nib forCellReuseIdentifier:JFICellID];
    
    // 高さの計算用のセルを登録
    [self.tableView registerNib:nib forCellReuseIdentifier:JFICellForHeightID];
    
    // セルの高さ計算用のオブジェクトをあらかじめ生成して変数に保持しておく
    self.cellForHeight = [self.tableView dequeueReusableCellWithIdentifier:JFICellForHeightID];
    
    // pull down to refresh
    self.refreshControl = UIRefreshControl.new;
    [self.refreshControl addTarget:self action:@selector(onRefresh) forControlEvents:UIControlEventValueChanged];
    
    if ([delegate.accounts count] > 0) {
        [self onRefresh];
    } else if (self.tabType == TabTypeHome) {
        // レイアウト確認用のダミーデータ
        self.entities = [NSMutableArray array];
        for (NSInteger i = 0; i < 40; i++) {
            [self.entities addObject:[[JFIEntity alloc] initDummy]];
        }
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JFIEntity *entity = [self.entities objectAtIndex:indexPath.row];
    return [self heightForEntity:entity];
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

- (CGFloat)heightForEntity:(JFIEntity *)entity
{
    if (entity == nil) {
        return 0;
    }
    
    // 高さの計算結果をキャッシュから参照
    if (entity.height != nil) {
        return [entity.height floatValue] + 2;
    }
    
    // NSLog(@"[JFITabViewController] heightForEntity no cache:%@", entity.statusID);
    
    self.cellForHeight.frame = self.tableView.bounds;
    
    [self.cellForHeight setLabelTexts:entity];
    [self.cellForHeight.contentView setNeedsLayout];
    [self.cellForHeight.contentView layoutIfNeeded];
    
    // 適切なサイズをAuto Layoutによって自動計算する
    float height = [self.cellForHeight.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    if ([entity.media count] > 0) {
        height+= [entity.media count] * 75 + 5;
    }
    
    // 高さの計算結果をキャッシュ
    entity.height =  @(height);
    
    // 自動計算で得られた高さを返す
    return height + 2;
}

- (void)scrollToTop
{
    [self.tableView setContentOffset:CGPointZero animated:YES];
}

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
            // ここで高さ計算してキャッシュしておかないとscrollToTopが正しく動作しない
            [self heightForEntity:tweet];
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

- (void)closeStatus:(NSNotification *)center
{
    NSLog(@"closeStatus");
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

#pragma mark - JFITabViewController

- (void)loadEntities
{
    [NSException raise:NSInternalInconsistencyException format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}

@end
