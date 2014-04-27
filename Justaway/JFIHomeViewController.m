#import "JFIEntity.h"
#import "JFIAppDelegate.h"
#import "JFIHomeViewController.h"

@interface JFIHomeViewController ()

@end

@implementation JFIHomeViewController

#pragma mark - JFITabViewController

- (void)load
{
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    STTwitterAPI *twitter = [delegate getTwitter];
    [twitter getHomeTimelineSinceID:nil
                              count:20
                       successBlock:^(NSArray *statuses) {
                           self.entities = [NSMutableArray array];
                           for (NSDictionary *dictionaly in statuses) {
                               [self.entities addObject:[[JFIEntity alloc] initWithStatus:dictionaly]];
                           }
                           [self.tableView reloadData];
                           [self.refreshControl endRefreshing];
                           // [delegate startStreaming];
                       } errorBlock:^(NSError *error) {
                           NSLog(@"-- error: %@", [error localizedDescription]);
                           [self.refreshControl endRefreshing];
                       }];
}

@end
