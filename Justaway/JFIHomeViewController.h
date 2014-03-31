#import <UIKit/UIKit.h>
#import "JFIStatusCell.h"
#import "STHTTPRequest+STTwitter.h"

@interface JFIHomeViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) NSOperationQueue *operationQueue;
@property (nonatomic) NSMutableArray *statuses;
@property (nonatomic) STHTTPRequest *streamingRequest;
@property (nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic) JFIStatusCell *cellForHeight;

@end
