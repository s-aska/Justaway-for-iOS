#import <UIKit/UIKit.h>

/*
 * UITableViewを抱えるすべてのUIViewControllerへ
 */

@interface JFIDiningViewController : UIViewController

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end
