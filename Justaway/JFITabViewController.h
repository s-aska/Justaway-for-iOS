#import <UIKit/UIKit.h>
#import "JFIConstants.h"
#import "JFIStatusCell.h"

@interface JFITabViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) TabType tabType;
@property (nonatomic) NSMutableArray *statuses;
@property (nonatomic) NSMutableArray *stacks;
@property (nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic) JFIStatusCell *cellForHeight;
@property (nonatomic) BOOL scrolling;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil tabType:(TabType)tabType;
- (void)finalizeWithDebounce:(CGFloat)delay;
- (void)receiveStatus:(NSNotification *)center;

@end
