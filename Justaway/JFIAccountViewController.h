#import <UIKit/UIKit.h>

@interface JFIAccountViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UIButton *rightButton;
@property (nonatomic, weak) IBOutlet UITableView *tableView;

- (IBAction)editAction:(id)sender;
- (IBAction)resetAction:(id)sender;
- (IBAction)loginInSafariAction:(id)sender;
- (IBAction)loginWithiOSAction:(id)sender;
- (IBAction)closeAction:(id)sender;

@end
