#import <UIKit/UIKit.h>
#import "JFIStatusCell.h"

@interface JFIHomeViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) NSMutableArray *statuses;
@property (nonatomic) NSMutableArray *stacks;
@property (nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic) JFIStatusCell *cellForHeight;

@end
