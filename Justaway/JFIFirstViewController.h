#import <UIKit/UIKit.h>
#import "JFIStatusCell.h"

@interface JFIFirstViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) NSOperationQueue *operationQueue;
@property (nonatomic) NSMutableArray *statuses;
@property (nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic) JFIStatusCell *cellForHeight;

@end
