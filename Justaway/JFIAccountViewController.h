#import <UIKit/UIKit.h>

@interface JFIAccountViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) NSOperationQueue *operationQueue;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIView *toolbarView;

- (IBAction)resetAction:(id)sender;
- (IBAction)loginInSafariAction:(id)sender;
- (IBAction)loginWithiOSAction:(id)sender;
- (IBAction)closeAction:(id)sender;

@end
