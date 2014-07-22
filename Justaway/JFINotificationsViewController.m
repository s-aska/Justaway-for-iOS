#import "JFIEntity.h"
#import "JFIAppDelegate.h"
#import "JFINotificationsViewController.h"

@interface JFINotificationsViewController ()

@end

@implementation JFINotificationsViewController

#pragma mark - JFITabViewController

- (void)loadEntities
{
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    STTwitterAPI *twitter = [delegate getTwitter];
    [twitter getMentionsTimelineSinceID:nil
                                  count:20
                           successBlock:^(NSArray *statuses) {
                               NSMutableArray *entities = NSMutableArray.new;
                               for (NSDictionary *dictionaly in statuses) {
                                   [entities addObject:[[JFIEntity alloc] initWithStatus:dictionaly]];
                               }
                               [self setEntities:entities];
                               [self.tableView reloadData];
                               [self.refreshControl endRefreshing];
                           } errorBlock:^(NSError *error) {
                               NSLog(@"-- error: %@", [error localizedDescription]);
                               [self.refreshControl endRefreshing];
                           }];
}

@end
