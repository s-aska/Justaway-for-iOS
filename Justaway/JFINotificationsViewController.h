#import <UIKit/UIKit.h>
#import "JFIDiningViewController.h"
#import "JFIStatusCell.h"

@interface JFINotificationsViewController : JFIDiningViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) NSMutableArray *statuses;
@property (nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic) JFIStatusCell *cellForHeight;

@end
