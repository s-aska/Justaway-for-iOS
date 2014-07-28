#import <UIKit/UIKit.h>
#import "JFIAccount.h"

@interface JFIAccountCell : UITableViewCell <UIAlertViewDelegate>

@property (nonatomic, weak) IBOutlet UILabel *displayNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *screenNameLabel;
@property (nonatomic, weak) IBOutlet UIImageView *iconImageView;
@property (nonatomic) NSString *themeName;
@property (nonatomic) NSString *userID;

- (void)setLabelTexts:(JFIAccount *)account;

- (IBAction)removeAction:(id)sender;

@end
