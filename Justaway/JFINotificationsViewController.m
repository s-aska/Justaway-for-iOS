#import "JFIAppDelegate.h"
#import "JFINotificationsViewController.h"

@interface JFINotificationsViewController ()

@end

@implementation JFINotificationsViewController

#pragma mark - JFITabViewController

- (void)load
{
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    STTwitterAPI *twitter = [delegate getTwitter];
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

@end
