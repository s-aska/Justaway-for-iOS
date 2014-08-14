#import <UIKit/UIKit.h>

@interface JFIProfileViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIView *profileView;
@property (nonatomic, weak) IBOutlet UIImageView *backgroundImageView;
@property (nonatomic, weak) IBOutlet UIImageView *iconImageView;
@property (nonatomic, weak) IBOutlet UILabel *displayName;
@property (nonatomic, weak) IBOutlet UILabel *scrennName;
@property (nonatomic, weak) IBOutlet UILabel *followedBy;

@property (nonatomic) NSString *userID;

- (IBAction)closeAction:(id)sender;

@end
