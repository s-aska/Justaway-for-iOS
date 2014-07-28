#import "JFIEntity.h"
#import "JFIAppDelegate.h"
#import "JFIMessagesViewController.h"

@interface JFIMessagesViewController ()

@end

@implementation JFIMessagesViewController

#pragma mark - JFITabViewController

- (void)loadEntities
{
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    STTwitterAPI *twitter = [delegate getTwitter];
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
        NSMutableArray *entities = NSMutableArray.new;
        for (NSDictionary *dictionaly in receivedRows) {
            [entities addObject:[[JFIEntity alloc] initWithMessage:dictionaly]];
        }
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:NO];
        [self setEntities:[[entities sortedArrayUsingDescriptors:@[sortDescriptor]] mutableCopy]];
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
