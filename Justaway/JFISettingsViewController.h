#import <UIKit/UIKit.h>
#import "JFIButton.h"

@interface JFISettingsViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIView *themeToolbarView;
@property (nonatomic, weak) IBOutlet UILabel *themeNameLabel;
@property (nonatomic) UIView *currenToolbarView;

- (IBAction)themeAction:(id)sender;
- (IBAction)accountAction:(id)sender;
- (IBAction)closeAction:(id)sender;

@end
