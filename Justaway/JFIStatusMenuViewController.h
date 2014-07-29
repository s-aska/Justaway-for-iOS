#import <UIKit/UIKit.h>

@interface JFIStatusMenuViewController : UIViewController

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UITableView *tableView;

- (IBAction)closeAction:(id)sender;

@end
