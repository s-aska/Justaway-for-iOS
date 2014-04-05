#import <UIKit/UIKit.h>
#import "JFIDiningViewController.h"
#import "JFIStatusCell.h"

@interface JFIHomeViewController : JFIDiningViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) NSMutableArray *statuses;
@property (nonatomic) NSMutableArray *stacks;
@property (nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic) JFIStatusCell *cellForHeight;

@end
