#import "JFIEntity.h"
#import "JFIAppDelegate.h"
#import "JFIHomeViewController.h"

@interface JFIHomeViewController ()

@end

@implementation JFIHomeViewController

#pragma mark - JFITabViewController

- (void)loadEntities
{
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    STTwitterAPI *twitter = [delegate getTwitter];
    [twitter getHomeTimelineSinceID:nil
                              count:200
                       successBlock:^(NSArray *statuses) {
                           NSMutableArray *entities = NSMutableArray.new;
                           for (NSDictionary *dictionaly in statuses) {
                               [entities addObject:[[JFIEntity alloc] initWithStatus:dictionaly]];
                           }
                           [self setEntities:entities];
                           [self.tableView reloadData];
                           [self.refreshControl endRefreshing];
                           if (delegate.streamingMode) {
                               [delegate startStreaming];
                           }
                       } errorBlock:^(NSError *error) {
                           NSLog(@"[%@] %s error:%@", NSStringFromClass([self class]), sel_getName(_cmd), [error localizedDescription]);
                           [self.refreshControl endRefreshing];
                       }];
}

@end
