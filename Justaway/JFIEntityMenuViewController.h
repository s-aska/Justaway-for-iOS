#import <UIKit/UIKit.h>

@interface JFIEntityMenuViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIButton *rightButton;

- (IBAction)sortAction:(id)sender;
- (IBAction)closeAction:(id)sender;

@end
