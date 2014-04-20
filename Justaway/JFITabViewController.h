#import <UIKit/UIKit.h>
#import "JFIStatusCell.h"

typedef NS_ENUM(NSInteger, TabType) {
    TabTypeHome,
    TabTypeNotifications,
    TabTypeMessages,
    TabTypeUserList,
};

@interface JFITabViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) TabType tabType;
@property (nonatomic) NSMutableArray *statuses;
@property (nonatomic) NSMutableArray *stacks;
@property (nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic) JFIStatusCell *cellForHeight;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil tabType:(TabType)tabType;

@end
