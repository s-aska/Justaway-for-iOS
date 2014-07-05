#import <UIKit/UIKit.h>
#import "JFIButton.h"

@interface JFISettingsViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIView *themeToolbarView;
@property (nonatomic, weak) IBOutlet UILabel *themeNameLabel;
@property (nonatomic, weak) IBOutlet UIView *fontSizeToolbarView;
@property (nonatomic, weak) IBOutlet UISlider *fontSizeSlider;
@property (nonatomic) UIView *currenToolbarView;

- (IBAction)fontSizeAction:(id)sender;
- (IBAction)themeAction:(id)sender;
- (IBAction)accountAction:(id)sender;
- (IBAction)closeAction:(id)sender;

@end
