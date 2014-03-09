#import <UIKit/UIKit.h>
#import "JFIStatusCell.h"

@interface JustawayFirstViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) NSArray *statuses;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) JFIStatusCell *cellForHeight;

- (IBAction)loadAction:(id)sender;

@end
