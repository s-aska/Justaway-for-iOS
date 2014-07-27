#import "JFIConstants.h"
#import "JFIEntity.h"
#import "JFIAccount.h"
#import "JFIAppDelegate.h"
#import "JFITabViewController.h"
#import "JFITheme.h"
#import "SVProgressHUD.h"
#import "LVDebounce.h"

@interface JFITabViewController ()

@property (nonatomic) NSMutableDictionary *heights;

@end

@implementation JFITabViewController

- (id)initWithType:(TabType)tabType
{
    self = [super init];
    if (self) {
        self.stacks = [@[] mutableCopy];
        self.tabType = tabType;
        self.heights = NSMutableDictionary.new;
    }
    return self;
}

- (void)loadView
{
	[super loadView];
}

- (void)setTheme
{
    JFITheme *theme = [JFITheme sharedTheme];
    [self.tableView setSeparatorColor:theme.mainHighlightBackgroundColor];
    [self.tableView setBackgroundColor:theme.mainBackgroundColor];
}

- (void)setFontSize
{
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    if (self.fontSize == delegate.fontSize) {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:JFIFinalizeFontSizeNotification
                                                            object:[[UIApplication sharedApplication] delegate]
                                                          userInfo:nil];
        
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @synchronized(self) {
            NSLog(@"[%@] %s heightForEntity.", NSStringFromClass([self class]), sel_getName(_cmd));
            
            self.fontSize = delegate.fontSize;
            for (JFIEntity *entity in self.entities) {
                [self heightForEntity:entity];
            }
            for (JFIEntity *entity in self.stacks) {
                [self heightForEntity:entity];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"[%@] %s reloadData.", NSStringFromClass([self class]), sel_getName(_cmd));
            
            // 表示セル・スクロール位置を保ちながらreloadData
            UITableViewCell *firstCell = [self.tableView.visibleCells firstObject];
            CGFloat offset = self.tableView.contentOffset.y - firstCell.frame.origin.y;
            NSIndexPath *firstPath;
            // セルが半分以上隠れているている場合、2番目の表示セルを基準にする
            if ([self.tableView.indexPathsForVisibleRows count] > 1 && offset > (firstCell.frame.size.height / 2)) {
                firstPath = [self.tableView.indexPathsForVisibleRows objectAtIndex:1];
                firstCell = [self.tableView cellForRowAtIndexPath:firstPath];
                offset = self.tableView.contentOffset.y - firstCell.frame.origin.y;
            } else {
                firstPath = [self.tableView.indexPathsForVisibleRows firstObject];
            }
            // NSLog(@"[%@] %s offset:%f", NSStringFromClass([self class]), sel_getName(_cmd), offset);
            [self.tableView reloadData];
            [self.tableView scrollToRowAtIndexPath:firstPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
            [self.tableView setContentOffset:CGPointMake(0.0, self.tableView.contentOffset.y + offset) animated:NO];
            
            [self loadImages];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:JFIFinalizeFontSizeNotification
                                                                object:[[UIApplication sharedApplication] delegate]
                                                              userInfo:nil];
            
            NSLog(@"[%@] %s complete.", NSStringFromClass([self class]), sel_getName(_cmd));
        });
    });
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    
    [self setTheme];
    
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    
    switch (self.tabType) {
        case TabTypeHome:
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(receiveStatus:)
                                                         name:JFIReceiveStatusNotification
                                                       object:delegate];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(destoryStatus:)
                                                         name:JFIDestroyStatusNotification
                                                       object:delegate];
            break;
        case TabTypeNotifications:
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(receiveEvent:)
                                                         name:JFIReceiveEventNotification
                                                       object:delegate];
            break;
        case TabTypeMessages:
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(receiveStatus:)
                                                         name:JFIReceiveMessageNotification
                                                       object:delegate];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(destoryMessage:)
                                                         name:JFIDestroyMessageNotification
                                                       object:delegate];
            break;
        case TabTypeUserList:
            break;
            
        default:
            break;
    }
    
    // テーマ設定
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setTheme)
                                                 name:JFISetThemeNotification
                                               object:delegate];
    
    // フォントサイズ設定
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setFontSize)
                                                 name:JFIApplyFontSizeNotification
                                               object:nil];
    
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(actionStatusChange)
                                                 name:JFIActionStatusNotification
                                               object:delegate];
    
    NSLog(@"[JFIHomeViewController] viewDidLoad accounts:%lu", (unsigned long)[delegate.accounts count]);
    
    self.fontSize = delegate.fontSize;
    
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
        NSMutableArray *entities = NSMutableArray.new;
        for (NSInteger i = 0; i < 40; i++) {
            [entities addObject:[[JFIEntity alloc] initDummy]];
        }
        [self setEntities:entities];
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
    
    JFIEntity *entity = [self.entities objectAtIndex:indexPath.row];
    
    if (cell.entity == entity) {
        return cell;
    }
    
    [cell setLabelTexts:entity];
    
    [cell.displayNameLabel sizeToFit];
    
    [cell loadImages];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JFIEntity *entity = [self.entities objectAtIndex:indexPath.row];
    if (entity != nil) {
        return [entity.height floatValue] + 2;
    } else {
        return 0;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"[%@] %s", NSStringFromClass([self class]), sel_getName(_cmd));
    JFIEntity *entity = [self.entities objectAtIndex:indexPath.row];
    if (entity == nil) {
        return;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:JFIOpenStatusNotification
                                                        object:[[UIApplication sharedApplication] delegate]
                                                      userInfo:@{@"entity": entity}];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // NSLog(@"[%@] %s", NSStringFromClass([self class]), sel_getName(_cmd));
    self.scrolling = YES;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    NSLog(@"[%@] %s", NSStringFromClass([self class]), sel_getName(_cmd));
    self.scrolling = YES;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        NSLog(@"[%@] %s", NSStringFromClass([self class]), sel_getName(_cmd));
        self.scrolling = NO;
        [LVDebounce fireAfter:JFIFinalizeInterval target:self selector:@selector(finalize) userInfo:nil];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSLog(@"[%@] %s", NSStringFromClass([self class]), sel_getName(_cmd));
    self.scrolling = NO;
    [LVDebounce fireAfter:JFIFinalizeInterval target:self selector:@selector(finalize) userInfo:nil];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    NSLog(@"[%@] %s", NSStringFromClass([self class]), sel_getName(_cmd));
	self.scrolling = NO;
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
    
    if ([self.entities count] > 0) {
        [self.refreshControl beginRefreshing];
    }
    
    [self loadEntities];
}

#pragma mark -

- (CGFloat)heightForEntity:(JFIEntity *)entity
{
    // 高さの計算結果をキャッシュから参照
    float fontSize = self.fontSize;
    if (entity.height != nil && entity.fontSize == fontSize) {
        return [entity.height floatValue] + 2;
    }
    
    /*
     * パターン毎にAuto Layoutの計算結果をキャッシュし高速化を図る
     * 不確定要素はstatusLabelとインライン画像なのでキャッシュしている基準値にそれぞれ加える
     */
    
    CGRect rect = [entity.text boundingRectWithSize:CGSizeMake(self.cellForHeight.statusLabel.frame.size.width, 0)
                                            options:NSStringDrawingUsesLineFragmentOrigin
                                         attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:fontSize + 12.0f]}
                                            context:nil];
    
    float textHeight = ceilf(rect.size.height);
    float cellHeight;
    NSString *pattern = entity.actionedUserID ? @"retweeted" : @"simple";
    if ([self.heights valueForKey:pattern]) {
        
        cellHeight = [[self.heights valueForKey:pattern] floatValue] + textHeight;
        
    } else {
        
        [self.cellForHeight setFrame:self.tableView.bounds];
        [self.cellForHeight setLabelTexts:entity];
        [self.cellForHeight setFontSize:fontSize];
        [self.cellForHeight.contentView setNeedsLayout];
        [self.cellForHeight.contentView layoutIfNeeded];
        
        // 適切なサイズをAuto Layoutによって自動計算する
        cellHeight = [self.cellForHeight.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
        
        [self.heights setValue:@(cellHeight - textHeight) forKey:pattern];
    }
    
    // 画像
    if ([entity.media count] > 0) {
        cellHeight+= [entity.media count] * 80.f;
    }
    
    // 高さの計算結果をキャッシュ
    entity.height =  @(cellHeight);
    entity.fontSize = fontSize;
    
    // 自動計算で得られた高さを返す
    return [entity.height floatValue] + 2;
}

- (void)scrollToTop
{
    [self.tableView setContentOffset:CGPointZero animated:YES];
}

- (void)finalize
{
    if (self.scrolling) {
        [LVDebounce fireAfter:JFIFinalizeInterval target:self selector:@selector(finalize) userInfo:nil];
        return;
    }
    if ([self.stacks count] == 0) {
        return;
    }
    @synchronized(self) {
        NSLog(@"[%@] %s", NSStringFromClass([self class]), sel_getName(_cmd));
        
        NSMutableArray *indexPaths = NSMutableArray.new;
        int index = 0;
        for (JFIEntity *entity in self.stacks) {
            [self.entities insertObject:entity atIndex:0];
            [indexPaths addObject:[NSIndexPath indexPathForRow:index inSection:0]];
            index++;
        }
        
        // 最上部表示時のみ自動スクロールする
        BOOL autoScroll = self.tableView.contentOffset.y > 0 && [self.tableView.visibleCells count] > 0 ? NO : YES;
        UITableViewCell *lastCell = [self.tableView.visibleCells lastObject];
        CGFloat offset = lastCell.frame.origin.y - self.tableView.contentOffset.y;
        [UIView setAnimationsEnabled:NO];
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
        if ([self.entities count] > 1000) {
            NSMutableArray *removeIndexPaths = NSMutableArray.new;
            NSMutableArray *removeEntities = NSMutableArray.new;
            for (NSInteger i = 1000; i < [self.entities count]; i++) {
                [removeEntities addObject:self.entities[i]];
                [removeIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
            for (JFIEntity *entity in removeEntities) {
                [self.entities removeObject:entity];
            }
            [self.tableView deleteRowsAtIndexPaths:removeIndexPaths withRowAnimation:UITableViewRowAnimationFade];
        }
        [self.tableView setContentOffset:CGPointMake(0.0, lastCell.frame.origin.y - offset) animated:NO];
        [UIView setAnimationsEnabled:YES];
        
        if (autoScroll) {
            [self scrollToTop];
        }
        
        self.stacks = [@[] mutableCopy];
        
        [self loadImages];
    }
}

- (void)loadImages
{
    for (JFIEntityCell *cell in self.tableView.visibleCells) {
        if (cell.iconImageView.image == nil) {
            [cell loadImages];
        }
    }
}

#pragma mark - NSNotificationCenter

- (void)receiveStatus:(NSNotification *)center
{
    // NSLog(@"[%@] %s", NSStringFromClass([self class]), sel_getName(_cmd));
    
    [self addStack:[center.userInfo valueForKey:@"entity"]];
    
    [LVDebounce fireAfter:JFIFinalizeInterval target:self selector:@selector(finalize) userInfo:nil];
}

- (void)receiveEvent:(NSNotification *)center
{
    NSLog(@"[%@] %s", NSStringFromClass([self class]), sel_getName(_cmd));
    
    [self addStack:[center.userInfo valueForKey:@"entity"]];
    
    [LVDebounce fireAfter:JFIFinalizeInterval target:self selector:@selector(finalize) userInfo:nil];
}

- (void)destoryStatus:(NSNotification *)center
{
    @synchronized(self) {
        JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
        NSString *statusID = [center.userInfo valueForKey:@"status_id"];
        BOOL retweetedByMe = [center.userInfo valueForKey:@"retweeted_by_me"] == nil ? NO : YES;
        NSInteger position = 0;
        NSMutableArray *indexPaths = NSMutableArray.new;
        NSMutableArray *removeEntities = NSMutableArray.new;
        JFIAccount *account = delegate.accounts[delegate.currentAccountIndex];
        NSString *actionedUserID = retweetedByMe ? account.userID : @"";
        for (JFIEntity *entity in self.entities) {
            if ([entity.statusID isEqualToString:statusID]) {
                if (!retweetedByMe || [actionedUserID isEqualToString:entity.actionedUserID]) {
                    [removeEntities addObject:entity];
                    [indexPaths addObject:[NSIndexPath indexPathForRow:position inSection:0]];
                }
            }
            position++;
        }
        if ([removeEntities count] > 0) {
            [self.tableView beginUpdates];
            for (JFIEntity *entity in removeEntities) {
                [self.entities removeObject:entity];
            }
            [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
    }
}

- (void)destoryMessage:(NSNotification *)center
{
    @synchronized(self) {
        NSString *messageID = [center.userInfo valueForKey:@"message_id"];
        NSInteger position = 0;
        NSMutableArray *indexPaths = NSMutableArray.new;
        NSMutableArray *removeEntities = NSMutableArray.new;
        for (JFIEntity *entity in self.entities) {
            if ([entity.messageID isEqualToString:messageID]) {
                [removeEntities addObject:entity];
                [indexPaths addObject:[NSIndexPath indexPathForRow:position inSection:0]];
            }
            position++;
        }
        if ([removeEntities count] > 0) {
            [self.tableView beginUpdates];
            for (JFIEntity *entity in removeEntities) {
                [self.entities removeObject:entity];
            }
            [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
    }
}

- (void)closeStatus:(NSNotification *)center
{
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (void)actionStatusChange
{
    for (JFIEntityCell *cell in self.tableView.visibleCells) {
        [cell setButtonColor];
    }
}

#pragma mark - JFITabViewController

- (void)setEntities:(NSArray *)entities
{
    @synchronized(self) {
        _entities = NSMutableArray.new;
        for (JFIEntity *entity in entities) {
            [self heightForEntity:entity];
            [self.entities addObject:entity];
        }
    }
}

- (void)addStack:(JFIEntity *)entity
{
    @synchronized(self) {
        [self heightForEntity:entity];
        [self.stacks addObject:entity];
    }
}

- (void)loadEntities
{
    [NSException raise:NSInternalInconsistencyException format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}

@end
