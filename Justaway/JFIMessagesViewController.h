#import <UIKit/UIKit.h>
#import "JFIDiningViewController.h"
#import "JFIMessageCell.h"

@interface JFIMessagesViewController : JFIDiningViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) NSMutableArray *messages;
@property (nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic) JFIMessageCell *cellForHeight;

@end
