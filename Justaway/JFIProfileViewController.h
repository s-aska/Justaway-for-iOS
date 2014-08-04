#import <UIKit/UIKit.h>

@interface JFIProfileViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIImageView *backgroundImageView;
@property (nonatomic, weak) IBOutlet UIImageView *iconImageView;

@property (nonatomic) NSString *userID;

- (IBAction)closeAction:(id)sender;

@end
