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
                           self.entities = [NSMutableArray array];
                           for (NSDictionary *dictionaly in statuses) {
                               JFIEntity *entity = [[JFIEntity alloc] initWithStatus:dictionaly];
                               [self heightForEntity:entity];
                               [self.entities addObject:entity];
                           }
                           [self.tableView reloadData];
                           [self.refreshControl endRefreshing];
                           if (delegate.streamingMode) {
                               [delegate startStreaming];
                           }
                       } errorBlock:^(NSError *error) {
                           NSLog(@"-- error: %@", [error localizedDescription]);
                           [self.refreshControl endRefreshing];
                       }];
}

@end
