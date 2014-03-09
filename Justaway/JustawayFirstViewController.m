#import "JustawayAppDelegate.h"
#import "JustawayFirstViewController.h"
#import "JFIStatusCell.h"
#import "ISDiskCache.h"
#import "ISMemoryCache.h"

@interface JustawayFirstViewController ()

@end

NSString *const JFI_CellId = @"Cell";
NSString *const JFI_CellForHeightId = @"CellForHeight";

@implementation JustawayFirstViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    JustawayAppDelegate *delegate = (JustawayAppDelegate *) [[UIApplication sharedApplication] delegate];
    
    NSLog(@"-- find accounts: %lu", (unsigned long)[delegate.accounts count]);
    
    // xibファイル名を指定しUINibオブジェクトを生成する
    UINib *nib = [UINib nibWithNibName:@"JFIStatusCell" bundle:nil];
    
    // UITableView#registerNib:forCellReuseIdentifierで、使用するセルを登録
    [_tableView registerNib:nib forCellReuseIdentifier:JFI_CellId];
    
    // 高さの計算用のセルを登録
    [_tableView registerNib:nib forCellReuseIdentifier:JFI_CellForHeightId];
    
    _tableView.dataSource = self;
    _tableView.delegate = self;
    
    // セルの高さ計算用のオブジェクトをあらかじめ生成して変数に保持しておく
    _cellForHeight = [_tableView dequeueReusableCellWithIdentifier:JFI_CellForHeightId];
    
    self.operationQueue = [[NSOperationQueue alloc] init];
    [self.operationQueue addObserver:self forKeyPath:@"operationCount" options:0 context:NULL];
    
    
    NSURL *url = [NSURL URLWithString:@"http://pbs.twimg.com/profile_images/418049488645677056/o2cmo8o2_normal.jpeg"];
    NSData *data = [NSData dataWithContentsOfURL:url];
    UIImage *image = [UIImage imageWithData:data];
    self.imageView.image = image;
    
    NSDictionary *status1 = @{
                              @"user.name": @"Shinichiro Aska",
                              @"user.screen_name": @"su_aska",
                              @"text": @"今日は鯖味噌の日。\n今日は鯖味噌の日。\n今日は鯖味噌の日。",
                              @"created_at": @"Wed Jun 06 20:07:10 +0000 2012",
                              @"user.profile_image_url": @"http://pbs.twimg.com/profile_images/435048335674580992/k2F3sHO2_normal.png"
                              };
    
    NSDictionary *status2 = @{
                              @"user.name": @"Shinichiro Aska",
                              @"user.screen_name": @"su_aska",
                              @"text": @"今日は鯖味噌の日。\n今日は鯖味噌の日。",
                              @"created_at": @"Wed Jun 06 20:07:10 +0000 2012",
                              @"user.profile_image_url": @"http://pbs.twimg.com/profile_images/435048335674580992/k2F3sHO2_normal.png"
                              };
    
    NSDictionary *status3 = @{
                              @"user.name": @"Shinichiro Aska",
                              @"user.screen_name": @"su_aska",
                              @"text": @"今日は鯖味噌の日。",
                              @"created_at": @"Wed Jun 06 20:07:10 +0000 2012",
                              @"user.profile_image_url": @"http://pbs.twimg.com/profile_images/435048335674580992/k2F3sHO2_normal.png"
                              };
    
    self.statuses = @[status1, status2, status3];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.operationQueue && [keyPath isEqualToString:@"operationCount"]) {
        NSInteger count = [self.operationQueue operationCount];
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = count > 0;
        });
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.statuses == nil) {
        return 0;
    } else {
        return [self.statuses count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"-- cellForRowAtIndexPath %@", indexPath);
    JFIStatusCell *cell = [tableView dequeueReusableCellWithIdentifier:JFI_CellId forIndexPath:indexPath];
    NSURL *URL;
    NSDictionary *status;
    
    // 起動時はダミーデータを表示（レイアウト調整の度にAPI呼ばない為）
    if (self.statuses == nil) {
        status = @{
                   @"user.name": @"Shinichiro Aska",
                   @"user.screen_name": @"@su_aska",
                   @"text": @"今日は鯖味噌の日。\n今日は鯖味噌の日。",
                   @"created_at": @"Wed Jun 06 20:07:10 +0000 2012",
                   @"user.profile_image_url": @"http://pbs.twimg.com/profile_images/435048335674580992/k2F3sHO2_normal.png"
                   };
    } else {
        status = [self.statuses objectAtIndex:indexPath.row];
    }
    
    URL = [NSURL URLWithString:[status valueForKeyPath:@"user.profile_image_url"]];
    
    [cell setLabelTexts:status];
    
    [cell.displayNameLabel sizeToFit];
    
    ISMemoryCache *memCache = [ISMemoryCache sharedCache];
    ISDiskCache *diskCache = [ISDiskCache sharedCache];
    
    cell.iconImageView.image = [memCache objectForKey:URL];
    
    if (cell.iconImageView.image == nil) {
        
        if ([diskCache hasObjectForKey:URL]) {
            NSLog(@"-- from disk %@", URL);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                UIImage *image = [diskCache objectForKey:URL];
                dispatch_async(dispatch_get_main_queue(), ^{
                    JFIStatusCell *cell = (JFIStatusCell *) [tableView cellForRowAtIndexPath:indexPath];
                    cell.iconImageView.image = image;
                    [cell setNeedsLayout];
                });
            });
        } else {
            NSLog(@"-- from network %@", URL);
            NSURLRequest *request = [NSURLRequest requestWithURL:URL];
            [NSURLConnection sendAsynchronousRequest:request
                                               queue:self.operationQueue
                                   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                       UIImage *image = [UIImage imageWithData:data];
                                       if (image) {
                                           [memCache setObject:image forKey:URL];
                                           [diskCache setObject:image forKey:URL];
                                           dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   JFIStatusCell *cell = (JFIStatusCell *) [tableView cellForRowAtIndexPath:indexPath];
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
        NSLog(@"-- from memory %@", URL);
    }
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.statuses == nil) {
        return 100;
    }
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

- (IBAction)loadAction:(id)sender
{
    
    JustawayAppDelegate *delegate = (JustawayAppDelegate *) [[UIApplication sharedApplication] delegate];
    
    // 必ず先頭のアカウントの情報を引いてくる罪深い処理
    NSInteger index = 0;
    STTwitterAPI *twitter = [delegate getTwitterByIndex:&index];
    
    [twitter getHomeTimelineSinceID:nil
                              count:20
                       successBlock:^(NSArray *statuses) {
                           self.statuses = statuses;
                           [self.tableView reloadData];
                       } errorBlock:^(NSError *error) {
                           NSLog(@"-- error: %@", [error localizedDescription]);
                       }];
}

@end
