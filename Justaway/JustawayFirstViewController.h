#import <UIKit/UIKit.h>
#import "JFIStatusCell.h"

@interface JustawayFirstViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) NSOperationQueue *operationQueue;
@property (nonatomic) NSArray *statuses;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) JFIStatusCell *cellForHeight;

- (IBAction)loadAction:(id)sender;

@end
